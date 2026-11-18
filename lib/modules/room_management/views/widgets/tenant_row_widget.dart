import 'package:flutter/material.dart';
import 'package:collection_agent/core/constants/app_colors.dart';
import 'package:collection_agent/core/constants/app_strings.dart';
import 'package:collection_agent/core/theme/app_text_styles.dart';
import 'package:collection_agent/shared/models/bed_model.dart';
import 'package:collection_agent/shared/models/room_model.dart';

/// Tenant Row in Room Card matching Screen 2
class TenantRowWidget extends StatelessWidget {
  final RoomModel room;
  final BedModel bed;
  final VoidCallback onPayTap;
  final VoidCallback onDetailsTap;

  const TenantRowWidget({
    super.key,
    required this.room,
    required this.bed,
    required this.onPayTap,
    required this.onDetailsTap,
  });

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final tenant = bed.tenant;
    if (tenant == null) {
      return const SizedBox.shrink();
    }

    final initials = tenant.initials;
    final name = tenant.name;
    final totalAmount = bed.totalAmount;
    final paidAmount = bed.paidAmount;
    final isSettled = tenant.isPaid;
    final isOverdue = tenant.isOverdue;
    final remainingAmount = isSettled
        ? 0.0
        : (tenant.combinedOutstandingDue > 0
            ? tenant.combinedOutstandingDue
            : (bed.remainingAmount > 0
                ? bed.remainingAmount
                : (totalAmount - paidAmount > 0 ? totalAmount - paidAmount : 0.0)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Initials Avatar
          GestureDetector(
            onTap: onDetailsTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.avatarBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.avatarText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name and Financial Breakdown (Due, Total, Paid)
          Expanded(
            child: GestureDetector(
              onTap: onDetailsTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (!isSettled) ...[
                    Text(
                      'Due: ${_formatCurrency(remainingAmount)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                      ),
                    ),
                    if (tenant.hasLastMonthPending) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${AppStrings.includesLastMonthDuePrefix}${_formatCurrency(tenant.lastMonthPendingAmount)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 1),
                    Text(
                      isOverdue
                          ? (paidAmount > 0
                              ? 'OVERDUE • Total: ${_formatCurrency(totalAmount)} • Paid: ${_formatCurrency(paidAmount)}'
                              : 'OVERDUE • Total: ${_formatCurrency(totalAmount)}')
                          : (paidAmount > 0
                              ? 'Total: ${_formatCurrency(totalAmount)} • Paid: ${_formatCurrency(paidAmount)}'
                              : 'Total: ${_formatCurrency(totalAmount)}'),
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isOverdue ? const Color(0xFFDC2626) : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      'Paid: ${_formatCurrency(paidAmount > 0 ? paidAmount : totalAmount)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Total: ${_formatCurrency(totalAmount)} • Settled',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Status / Action Button
          if (isSettled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppStrings.paid,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: onPayTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isOverdue ? const Color(0xFFDC2626) : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                AppStrings.pay,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
