import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collection_agent/core/constants/app_strings.dart';
import 'package:collection_agent/modules/room_management/views/widgets/customer_details_bottom_sheet.dart';
import 'package:collection_agent/shared/models/tenant_model.dart';

void main() {
  group('CustomerDetailsBottomSheet Widget Tests', () {
    testWidgets('renders full Current Month Rent and not due amount after partial payment', (tester) async {
      // Tenant with total rent ₹10,000, paid ₹4,000, due ₹6,000
      final tenant = TenantModel(
        id: 'user-45',
        customerId: 'PG01',
        name: 'Loki',
        email: 'loki@example.com',
        phone: '9876543210',
        dob: '2000-01-01',
        joiningDate: '2026-10-01',
        gender: 'male',
        idProofs: const [],
        emergencyContact1: '1234567890',
        emergencyContact2: '',
        roomNumber: '101',
        blockName: 'Block A',
        status: 'Active',
        totalRentAmount: 10000.0,
        amountDue: 6000.0,
        balancePayable: 6000.0,
        rentPaidAmount: 4000.0,
        totalOutstandingDue: 6000.0,
        paymentStatus: 'due',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerDetailsBottomSheet(tenant: tenant),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Current Month Rent label must be present
      expect(find.text(AppStrings.currentMonthRent), findsOneWidget);

      // Must display ₹10,000 as Current Month Rent, NOT ₹6,000
      expect(find.text('₹10,000'), findsOneWidget);

      // Partial payment breakdown subtitle must be present
      expect(find.text('Paid: ₹4,000 (Due: ₹6,000)'), findsOneWidget);

      // Total Outstanding Due label and value (₹6,000)
      expect(find.text(AppStrings.totalOutstandingDue), findsOneWidget);
      expect(find.text('₹6,000'), findsOneWidget);
    });
  });
}
