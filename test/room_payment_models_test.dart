import 'package:flutter_test/flutter_test.dart';
import 'package:collection_agent/core/utils/validators.dart';
import 'package:collection_agent/shared/models/bed_model.dart';
import 'package:collection_agent/shared/models/room_model.dart';
import 'package:collection_agent/shared/models/tenant_model.dart';

void main() {
  group('Payment Models Calculation & Invariants Tests', () {
    test('Scenario 1: Fresh Unpaid Tenant (No payment yet)', () {
      final json = {
        'id': '101',
        'name': 'Rahul Sharma',
        'amount_due': 10000.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 10000.0,
        'total_amount': 10000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(json);
      final bed = BedModel(
        id: 'bed-1',
        bedNumber: 1,
        tenant: tenant,
        amountDue: tenant.dueAmount,
        isPaid: tenant.isPaid,
      );

      expect(tenant.totalRent, 10000.0);
      expect(tenant.dueAmount, 10000.0);
      expect(tenant.rentPaidAmount, 0.0);
      expect(tenant.isPaid, false);

      expect(bed.totalAmount, 10000.0);
      expect(bed.remainingAmount, 10000.0);
      expect(bed.paidAmount, 0.0);
    });

    test('Scenario 2: Partial Payment of ₹4,000 (Expected fix verification)', () {
      // Backend updates amount_due to 6000, records 4000 in transactions, returns total_amount 10000
      final json = {
        'id': '101',
        'name': 'Rahul Sharma',
        'amount_due': 6000.0,
        'rent_paid_amount': 4000.0,
        'balance_payable': 6000.0,
        'total_amount': 10000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(json);
      final bed = BedModel(
        id: 'bed-1',
        bedNumber: 1,
        tenant: tenant,
        amountDue: tenant.dueAmount,
        isPaid: tenant.isPaid,
      );

      // Verify that total rent DOES NOT drop to 6000
      expect(tenant.totalRent, 10000.0);
      expect(tenant.dueAmount, 6000.0);
      expect(tenant.rentPaidAmount, 4000.0);
      expect(tenant.isPaid, false);

      expect(bed.totalAmount, 10000.0);
      expect(bed.remainingAmount, 6000.0);
      expect(bed.paidAmount, 4000.0);
    });

    test('Scenario 3: Backward compatibility when backend does not send total_amount', () {
      // Older backend only sends amount_due and rent_paid_amount
      final legacyJson = {
        'id': '102',
        'name': 'Amit Kumar',
        'amount_due': 3500.0,
        'rent_paid_amount': 6500.0,
        'balance_payable': 3500.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(legacyJson);
      final bed = BedModel(
        id: 'bed-2',
        bedNumber: 2,
        tenant: tenant,
        amountDue: tenant.dueAmount,
        isPaid: tenant.isPaid,
      );

      // Reconstructed mathematically: 3500 + 6500 = 10000
      expect(tenant.totalRent, 10000.0);
      expect(tenant.dueAmount, 3500.0);
      expect(tenant.rentPaidAmount, 6500.0);

      expect(bed.totalAmount, 10000.0);
      expect(bed.remainingAmount, 3500.0);
      expect(bed.paidAmount, 6500.0);
    });

    test('Scenario 4: Fully Settled Tenant', () {
      final json = {
        'id': '103',
        'name': 'Priya Patel',
        'amount_due': 0.0,
        'rent_paid_amount': 10000.0,
        'balance_payable': 0.0,
        'total_amount': 10000.0,
        'payment_status': 'paid',
      };

      final tenant = TenantModel.fromJson(json);
      final bed = BedModel(
        id: 'bed-3',
        bedNumber: 3,
        tenant: tenant,
        amountDue: tenant.dueAmount,
        isPaid: tenant.isPaid,
      );

      expect(tenant.isPaid, true);
      expect(tenant.totalRent, 10000.0);
      expect(tenant.dueAmount, 0.0);
      expect(tenant.rentPaidAmount, 10000.0);

      expect(bed.totalAmount, 10000.0);
      expect(bed.remainingAmount, 0.0);
      expect(bed.paidAmount, 10000.0);
    });

    test('Scenario 5: Room Card Aggregation with mixed Partial and Paid Beds', () {
      // Bed 1: Partial payment (Rent: 10,000, Paid: 4,000, Due: 6,000)
      final tenant1 = TenantModel.fromJson({
        'id': '1',
        'name': 'Tenant 1',
        'amount_due': 6000.0,
        'rent_paid_amount': 4000.0,
        'balance_payable': 6000.0,
        'total_amount': 10000.0,
        'payment_status': 'due',
      });
      final bed1 = BedModel(
        id: 'bed-1',
        bedNumber: 1,
        tenant: tenant1,
        amountDue: tenant1.dueAmount,
        isPaid: tenant1.isPaid,
      );

      // Bed 2: Fully paid (Rent: 12,000, Paid: 12,000, Due: 0)
      final tenant2 = TenantModel.fromJson({
        'id': '2',
        'name': 'Tenant 2',
        'amount_due': 0.0,
        'rent_paid_amount': 12000.0,
        'balance_payable': 0.0,
        'total_amount': 12000.0,
        'payment_status': 'paid',
      });
      final bed2 = BedModel(
        id: 'bed-2',
        bedNumber: 2,
        tenant: tenant2,
        amountDue: tenant2.dueAmount,
        isPaid: tenant2.isPaid,
      );

      final room = RoomModel(
        id: 'room-101',
        roomNumber: '101',
        blockId: 'block-A',
        beds: [bed1, bed2],
      );

      // Room Total = 10,000 + 12,000 = 22,000
      expect(room.totalAmount, 22000.0);
      // Room Paid = 4,000 + 12,000 = 16,000
      expect(room.paidAmount, 16000.0);
      // Room Remaining Due = 6,000 + 0 = 6,000
      expect(room.remainingAmount, 6000.0);
      // Invariant: Total == Paid + Remaining
      expect(room.totalAmount, room.paidAmount + room.remainingAmount);
    });

    test('Scenario 6: Newly Created Customer with no payments made', () {
      // Newly created customer: amount_due = 8000, rent_paid_amount = 0, payment_status = 'due'
      final json = {
        'id': '103',
        'name': 'New Customer',
        'amount_due': 8000.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 8000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.isPaid, false);
      expect(tenant.isDue, true);
      expect(tenant.dueAmount, 8000.0);

      // Even if zero amounts were sent without a payment record:
      final unbilledJson = {
        'id': '104',
        'name': 'Unbilled Customer',
        'amount_due': 0.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 0.0,
        'payment_status': 'due',
      };
      final unbilledTenant = TenantModel.fromJson(unbilledJson);
      expect(unbilledTenant.isPaid, false); // Crucial: must NOT be marked as paid
    });

    test('Scenario 7: Customer with Overdue payment', () {
      final json = {
        'id': '105',
        'name': 'Overdue Customer',
        'amount_due': 5000.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 5000.0,
        'payment_status': 'overdue',
        'due_date': '2026-10-07',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.isPaid, false);
      expect(tenant.isOverdue, true);
      expect(tenant.dueAmount, 5000.0);
    });

    test('Scenario 8: Tenant with Pending Last Month Fee (Actual Issue Fix)', () {
      final json = {
        'id': '106',
        'name': 'Arun Verma',
        'amount_due': 8000.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 8000.0,
        'total_amount': 8000.0,
        'payment_status': 'due',
        'last_month_pending_amount': 4500.0,
        'last_month_cycle': 'September 2026',
        'total_outstanding_due': 12500.0,
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.dueAmount, 8000.0);
      expect(tenant.lastMonthPendingAmount, 4500.0);
      expect(tenant.lastMonthCycle, 'September 2026');
      expect(tenant.hasLastMonthPending, true);
      expect(tenant.totalOutstandingDue, 12500.0);
      expect(tenant.combinedOutstandingDue, 12500.0);
    });

    test('Scenario 9: Tenant with Settled Previous Cycles', () {
      final json = {
        'id': '107',
        'name': 'Suresh Raina',
        'amount_due': 7000.0,
        'rent_paid_amount': 2000.0,
        'balance_payable': 5000.0,
        'total_amount': 7000.0,
        'payment_status': 'due',
        'last_month_pending_amount': 0.0,
        'last_month_cycle': '',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.dueAmount, 5000.0);
      expect(tenant.lastMonthPendingAmount, 0.0);
      expect(tenant.hasLastMonthPending, false);
      expect(tenant.combinedOutstandingDue, 5000.0);
    });

    test('Scenario 10: Payment Profile Deserialization with Billing Cycle History', () {
      final profileJson = {
        'id': '108',
        'user_id': 42,
        'name': 'Pooja Hegde',
        'customer_id': 'TS-0042',
        'amount_due': 9000.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 9000.0,
        'total_amount': 9000.0,
        'last_month_pending_amount': 3000.0,
        'last_month_cycle': 'August 2026',
        'total_outstanding_due': 12000.0,
        'recent_cycles': [
          {
            'payment_id': 11,
            'cycle_name': 'October 2026',
            'total_amount': 9000.0,
            'paid_amount': 0.0,
            'due_amount': 9000.0,
            'status': 'due',
            'is_past_cycle': false,
          },
          {
            'payment_id': 10,
            'cycle_name': 'September 2026',
            'total_amount': 9000.0,
            'paid_amount': 6000.0,
            'due_amount': 3000.0,
            'status': 'partial',
            'is_past_cycle': true,
          },
          {
            'payment_id': 9,
            'cycle_name': 'August 2026',
            'total_amount': 9000.0,
            'paid_amount': 9000.0,
            'due_amount': 0.0,
            'status': 'paid',
            'is_past_cycle': true,
          },
        ],
      };

      final tenant = TenantModel.fromJson(profileJson);
      expect(tenant.name, 'Pooja Hegde');
      expect(tenant.userId, 42);
      expect(tenant.hasLastMonthPending, true);
      expect(tenant.lastMonthPendingAmount, 3000.0);
      expect(tenant.lastMonthCycle, 'August 2026');
      expect(tenant.recentCycles.length, 3);

      final cycle1 = tenant.recentCycles[0];
      expect(cycle1.cycleName, 'October 2026');
      expect(cycle1.dueAmount, 9000.0);
      expect(cycle1.isPastCycle, false);

      final cycle2 = tenant.recentCycles[1];
      expect(cycle2.cycleName, 'September 2026');
      expect(cycle2.paidAmount, 6000.0);
      expect(cycle2.dueAmount, 3000.0);
      expect(cycle2.isPastCycle, true);

      final cycle3 = tenant.recentCycles[2];
      expect(cycle3.cycleName, 'August 2026');
      expect(cycle3.paidAmount, 9000.0);
      expect(cycle3.dueAmount, 0.0);
      expect(cycle3.status, 'paid');
    });

    test('Scenario 7: Due amount fallback when balance_payable is omitted/null in JSON', () {
      final jsonWithoutBalance = {
        'id': '105',
        'name': 'Karthik Raja',
        'total_amount': 6000.0,
        'rent_paid_amount': 0.0,
        'amount_due': 6000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(jsonWithoutBalance);
      expect(tenant.balancePayable, 6000.0);
      expect(tenant.dueAmount, 6000.0);
      expect(tenant.totalRent, 6000.0);

      final bed = BedModel.fromJson({
        'id': 'bed-7',
        'bedNumber': 1,
        'tenant': tenant.toJson(),
      });
      expect(bed.remainingAmount, 6000.0);
      expect(bed.amountDue, 6000.0);
    });

    test('Scenario 8: Due amount fallback when balancePayable & amountDue are 0 but totalRent is 6000 & rentPaid is 0', () {
      final jsonUnsetDue = {
        'id': '106',
        'name': 'Suresh Kumar',
        'total_amount': 6000.0,
        'rent_paid_amount': 0.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(jsonUnsetDue);
      expect(tenant.dueAmount, 6000.0);
      expect(tenant.totalRent, 6000.0);
      expect(tenant.isPaid, false);
    });

    test('Scenario 11: Multi-Month Due: Last month due 6k + Current month rent 6k (Total 12k Full Payment Fix)', () {
      final json = {
        'id': '109',
        'name': 'Manoj Bajpayee',
        'amount_due': 6000.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 6000.0,
        'total_amount': 6000.0,
        'last_month_pending_amount': 6000.0,
        'last_month_cycle': 'September 2026',
        'total_outstanding_due': 12000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.dueAmount, 6000.0);
      expect(tenant.lastMonthPendingAmount, 6000.0);
      expect(tenant.combinedOutstandingDue, 12000.0);
      expect(tenant.hasLastMonthPending, true);

      final bed = BedModel.fromJson({
        'id': 'bed-109',
        'bedNumber': 1,
        'tenant': tenant.toJson(),
      });

      // Bed remainingAmount must be 12,000 (not 6,000) so Full Payment selects 12k
      expect(bed.remainingAmount, 12000.0);
      expect(bed.amountDue, 12000.0);

      // Verify that when tenant is marked paid, remaining is 0
      final settledBed = bed.copyWith(
        tenant: tenant.copyWith(
          paymentStatus: 'paid',
          lastMonthPendingAmount: 0.0,
          totalOutstandingDue: 0.0,
        ),
      );
      expect(settledBed.remainingAmount, 0.0);
    });

    test('Scenario 12: Room having 2 users - User 1 (last month 6k + current month 6k) and User 2 (10k) shows Room Total 22k and Remaining 22k', () {
      final user1Json = {
        'id': '100-1',
        'name': 'loki',
        'amount_due': 6000.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 6000.0,
        'total_amount': 6000.0,
        'last_month_pending_amount': 6000.0,
        'last_month_cycle': 'September 2026',
        'total_outstanding_due': 12000.0,
        'payment_status': 'due',
      };

      final user2Json = {
        'id': '100-2',
        'name': 'SON',
        'amount_due': 10000.0,
        'rent_paid_amount': 0.0,
        'balance_payable': 10000.0,
        'total_amount': 10000.0,
        'last_month_pending_amount': 0.0,
        'total_outstanding_due': 10000.0,
        'payment_status': 'due',
      };

      final tenant1 = TenantModel.fromJson(user1Json);
      final tenant2 = TenantModel.fromJson(user2Json);

      final bed1 = BedModel(
        id: 'bed-1',
        bedNumber: 1,
        tenant: tenant1,
        amountDue: tenant1.combinedOutstandingDue,
        isPaid: tenant1.isPaid,
      );

      final bed2 = BedModel(
        id: 'bed-2',
        bedNumber: 2,
        tenant: tenant2,
        amountDue: tenant2.combinedOutstandingDue,
        isPaid: tenant2.isPaid,
      );

      final room = RoomModel(
        id: 'room-100',
        roomNumber: '100',
        blockId: 'block-1',
        beds: [bed1, bed2],
      );

      // Verify User 1 (loki) bed totals
      expect(bed1.totalAmount, 12000.0);
      expect(bed1.remainingAmount, 12000.0);
      expect(bed1.paidAmount, 0.0);

      // Verify User 2 (SON) bed totals
      expect(bed2.totalAmount, 10000.0);
      expect(bed2.remainingAmount, 10000.0);
      expect(bed2.paidAmount, 0.0);

      // Verify Room 100 Aggregates: Total = 22k, Remaining = 22k, Paid = 0
      expect(room.totalAmount, 22000.0);
      expect(room.remainingAmount, 22000.0);
      expect(room.paidAmount, 0.0);
    });

    test('Scenario 13: Single-Cycle Overdue Tenant with no previous month dues (Fix for double-counting bug)', () {
      // Backend returns single overdue payment of ₹9,677.42 with last_month_pending_amount = 0
      final json = {
        'id': '29',
        'name': 'MO-ACT Profile Fixture',
        'amount_due': 9677.42,
        'rent_paid_amount': 0.0,
        'balance_payable': 9677.42,
        'total_amount': 9677.42,
        'last_month_pending_amount': 0.0,
        'last_month_cycle': '',
        'total_outstanding_due': 9677.42,
        'payment_status': 'overdue',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.dueAmount, 9677.42);
      expect(tenant.lastMonthPendingAmount, 0.0);
      expect(tenant.hasLastMonthPending, false);
      expect(tenant.combinedOutstandingDue, 9677.42);

      final bed = BedModel(
        id: 'bed-29',
        bedNumber: 1,
        tenant: tenant,
        amountDue: tenant.combinedOutstandingDue,
        isPaid: tenant.isPaid,
      );

      // Must be 9,677.42 (NOT 19,355)
      expect(bed.remainingAmount, 9677.42);
      expect(bed.amountDue, 9677.42);
    });

    test('Scenario 14: Partial Payment maintains full totalRent in customer details model', () {
      // Tenant has monthly rent of ₹10,000, pays ₹4,000 partially, leaving balance of ₹6,000
      final json = {
        'id': '45',
        'name': 'Loki',
        'amount_due': 6000.0,
        'rent_paid_amount': 4000.0,
        'balance_payable': 6000.0,
        'total_amount': 10000.0,
        'last_month_pending_amount': 0.0,
        'total_outstanding_due': 6000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(json);

      // Verify that Current Month Rent displays totalRent (10,000), not dueAmount (6,000)
      expect(tenant.totalRent, 10000.0);
      expect(tenant.dueAmount, 6000.0);
      expect(tenant.rentPaidAmount, 4000.0);
      expect(tenant.combinedOutstandingDue, 6000.0);
    });

    test('Scenario 15: Full Payment of remaining ₹6,000 settles bed and passes validation without excess error', () {
      final json = {
        'id': '45',
        'name': 'Loki',
        'amount_due': 6000.0,
        'rent_paid_amount': 4000.0,
        'balance_payable': 6000.0,
        'total_amount': 10000.0,
        'last_month_pending_amount': 0.0,
        'total_outstanding_due': 6000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(json);
      final bed = BedModel(
        id: 'bed-45',
        bedNumber: 1,
        tenant: tenant,
        amountDue: tenant.dueAmount,
        isPaid: tenant.isPaid,
      );

      final totalDue = bed.remainingAmount > 0 ? bed.remainingAmount : bed.amountDue;
      expect(totalDue, 6000.0);

      // Paying full 6000 must NOT throw paymentExceedsDue
      final fullPaymentStr = totalDue.toStringAsFixed(totalDue.truncateToDouble() == totalDue ? 0 : 2);
      expect(fullPaymentStr, '6000');
      expect(Validators.validateAmount(fullPaymentStr, totalDue), isNull);
    });

    test('Scenario 16: Tenant with current month balance 0 but last month pending 6000 is NOT isPaid', () {
      final json = {
        'id': '46',
        'name': 'Pending Last Month Tenant',
        'amount_due': 0.0,
        'rent_paid_amount': 6000.0,
        'balance_payable': 0.0,
        'total_amount': 6000.0,
        'last_month_pending_amount': 6000.0,
        'last_month_cycle': 'Oct 2026',
        'total_outstanding_due': 6000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.isPaid, false);
      expect(tenant.hasLastMonthPending, true);
      expect(tenant.lastMonthPendingAmount, 6000.0);
      expect(tenant.combinedOutstandingDue, 6000.0);

      final bed = BedModel(
        id: 'bed-46',
        bedNumber: 1,
        tenant: tenant,
        amountDue: tenant.combinedOutstandingDue,
        isPaid: tenant.isPaid,
      );
      expect(bed.isPaid, false);
      expect(bed.remainingAmount, 6000.0);
    });

    test('Scenario 17: Room change from 10k to 20k with 5k partial payment already paid', () {
      final json = {
        'id': '60',
        'name': 'Room Changed Tenant',
        'amount_due': 15000.0,
        'rent_paid_amount': 5000.0,
        'balance_payable': 15000.0,
        'total_amount': 20000.0,
        'last_month_pending_amount': 0.0,
        'last_month_cycle': '',
        'total_outstanding_due': 15000.0,
        'payment_status': 'due',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.isPaid, false);
      expect(tenant.dueAmount, 15000.0);
      expect(tenant.totalRent, 20000.0);
      expect(tenant.rentPaidAmount, 5000.0);
      expect(tenant.combinedOutstandingDue, 15000.0);

      final bed = BedModel(
        id: 'bed-60',
        bedNumber: 1,
        tenant: tenant,
        amountDue: tenant.combinedOutstandingDue,
        isPaid: tenant.isPaid,
      );

      expect(bed.isPaid, false);
      expect(bed.totalAmount, 20000.0);
      expect(bed.paidAmount, 5000.0);
      expect(bed.remainingAmount, 15000.0);

      final fullPaymentStr = bed.remainingAmount.toStringAsFixed(
        bed.remainingAmount.truncateToDouble() == bed.remainingAmount ? 0 : 2,
      );
      expect(fullPaymentStr, '15000');
      expect(Validators.validateAmount(fullPaymentStr, bed.remainingAmount), isNull);
    });

    test('Scenario 18: Room change where old record had payment_status paid but totalOutstandingDue is 15000', () {
      final json = {
        'id': '61',
        'name': 'Edge Case Settled Flag Tenant',
        'amount_due': 15000.0,
        'rent_paid_amount': 5000.0,
        'balance_payable': 15000.0,
        'total_amount': 20000.0,
        'last_month_pending_amount': 0.0,
        'last_month_cycle': '',
        'total_outstanding_due': 15000.0,
        'payment_status': 'paid',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.isPaid, false);
      expect(tenant.dueAmount, 15000.0);
      expect(tenant.combinedOutstandingDue, 15000.0);

      final bed = BedModel.fromJson({
        'id': 'bed-61',
        'bedNumber': 1,
        'tenant': json,
        'amountDue': 15000.0,
        'isPaid': false,
      });

      expect(bed.isPaid, false);
      expect(bed.remainingAmount, 15000.0);
    });

    test('Scenario 19: Settled tenant after full payment (Gokilavani C fix)', () {
      final json = {
        'id': '3',
        'name': 'Gokilavani C',
        'payment_id': 2,
        'amount_due': 0.0,
        'rent_paid_amount': 8000.0,
        'balance_payable': 0.0,
        'total_amount': 8000.0,
        'last_month_pending_amount': 0.0,
        'last_month_cycle': '',
        'total_outstanding_due': 0.0,
        'payment_status': 'paid',
        'due_date': '2026-11-05',
      };

      final tenant = TenantModel.fromJson(json);
      expect(tenant.isPaid, true);
      expect(tenant.isOverdue, false);
      expect(tenant.isDue, false);
      expect(tenant.dueAmount, 0.0);
      expect(tenant.combinedOutstandingDue, 0.0);
      expect(tenant.totalRent, 8000.0);
      expect(tenant.rentPaidAmount, 8000.0);

      final bed = BedModel(
        id: 'bed-3',
        bedNumber: 1,
        tenant: tenant,
        amountDue: tenant.dueAmount,
        isPaid: tenant.isPaid,
      );

      expect(bed.isPaid, true);
      expect(bed.remainingAmount, 0.0);
      expect(bed.paidAmount, 8000.0);
      expect(bed.totalAmount, 8000.0);
    });
  });
}
