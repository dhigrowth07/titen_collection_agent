import 'package:collection_agent/shared/models/tenant_model.dart';

/// Bed Domain Model
class BedModel {
  final String id;
  final int bedNumber;
  final TenantModel? tenant;
  final double amountDue;
  final bool isPaid;

  const BedModel({
    required this.id,
    required this.bedNumber,
    this.tenant,
    required this.amountDue,
    required this.isPaid,
  });

  bool get isVacant => tenant == null;
  double get totalAmount {
    if (tenant != null) {
      return tenant!.totalRent + tenant!.lastMonthPendingAmount;
    }
    return amountDue;
  }
  double get paidAmount => tenant?.rentPaidAmount ?? 0.0;
  double get remainingAmount {
    if (tenant != null) {
      if (tenant!.isPaid) return 0.0;
      return tenant!.combinedOutstandingDue > 0
          ? tenant!.combinedOutstandingDue
          : tenant!.dueAmount;
    }
    return isPaid ? 0.0 : amountDue;
  }

  factory BedModel.fromJson(Map<String, dynamic> json) {
    final tenantObj = json['tenant'] != null
        ? TenantModel.fromJson(json['tenant'] as Map<String, dynamic>)
        : null;
    final rawDue = (json['amountDue'] as num?)?.toDouble() ?? 0.0;
    final isPaidVal = json['isPaid'] as bool? ?? false;
    final effectiveDue = tenantObj != null
        ? (tenantObj.combinedOutstandingDue > 0 ? tenantObj.combinedOutstandingDue : tenantObj.dueAmount)
        : rawDue;
    return BedModel(
      id: json['id'] as String? ?? '',
      bedNumber: json['bedNumber'] as int? ?? 1,
      tenant: tenantObj,
      amountDue: effectiveDue,
      isPaid: tenantObj?.isPaid ?? isPaidVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedNumber': bedNumber,
      'tenant': tenant?.toJson(),
      'amountDue': amountDue,
      'isPaid': isPaid,
    };
  }

  BedModel copyWith({
    String? id,
    int? bedNumber,
    TenantModel? tenant,
    double? amountDue,
    bool? isPaid,
  }) {
    return BedModel(
      id: id ?? this.id,
      bedNumber: bedNumber ?? this.bedNumber,
      tenant: tenant ?? this.tenant,
      amountDue: amountDue ?? this.amountDue,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
