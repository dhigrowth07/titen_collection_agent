import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:collection_agent/core/constants/app_colors.dart';
import 'package:collection_agent/core/constants/app_strings.dart';
import 'package:collection_agent/core/theme/app_text_styles.dart';
import 'package:collection_agent/modules/room_management/viewmodel/room_management_viewmodel.dart';

/// Screen 3: Payment Collection Modal Bottom Sheet
/// STRICT RULES: Public StatelessWidget, NO setState(), observed with Selector
class PaymentBottomSheet extends StatelessWidget {
  const PaymentBottomSheet({super.key});

  static void show(BuildContext context, [RoomManagementViewModel? viewModel]) {
    final vm = viewModel ?? context.read<RoomManagementViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: const PaymentBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RoomManagementViewModel>();
    final activeBed = vm.activeBedForPayment;
    final roomNumber = vm.activeRoomNumberForPayment ?? '';
    final tenantName = activeBed?.tenant?.name ?? 'Tenant';
    final tenantDue = activeBed?.tenant?.combinedOutstandingDue ?? 0.0;
    final bedDue = activeBed?.remainingAmount ?? 0.0;
    final rawDue = tenantDue > 0
        ? tenantDue
        : (bedDue > 0 ? bedDue : (activeBed?.amountDue ?? 0.0));
    final amountDue = double.parse(rawDue.toStringAsFixed(2));
    final formattedDue = '${AppStrings.currencySymbol}${amountDue.toStringAsFixed(amountDue.truncateToDouble() == amountDue ? 0 : 2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 10,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFA3B899),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row: Title and Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$roomNumber - $tenantName',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          const SizedBox(height: 16),

          // Amount Due Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activeBed != null && activeBed.paidAmount > 0
                    ? AppStrings.remainingToPay
                    : AppStrings.amountDue,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: activeBed != null && activeBed.paidAmount > 0
                      ? const Color(0xFFDC2626)
                      : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              Text(
                formattedDue,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: activeBed != null && activeBed.paidAmount > 0
                      ? const Color(0xFFDC2626)
                      : AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (activeBed != null && activeBed.paidAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.totalRentPrefix}${AppStrings.currencySymbol}${activeBed.totalAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${AppStrings.alreadyPaidPrefix}${AppStrings.currencySymbol}${activeBed.paidAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (activeBed?.tenant?.hasLastMonthPending == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDBA74), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: '${AppStrings.includesLastMonthDuePrefix}${AppStrings.currencySymbol}${activeBed!.tenant!.lastMonthPendingAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF9A3412),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        children: [
                          if (activeBed.tenant!.lastMonthCycle.isNotEmpty)
                            TextSpan(
                              text: ' (${activeBed.tenant!.lastMonthCycle})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Field 1: Full / Partial Payment Dropdown
          Text(
            AppStrings.fullPartialPayment,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Selector<RoomManagementViewModel, String>(
            selector: (_, vm) => vm.paymentType,
            builder: (context, paymentType, _) {
              return Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: paymentType == AppStrings.selectPayment ? null : paymentType,
                    hint: Text(
                      AppStrings.selectPayment,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    items: [
                      AppStrings.fullPayment,
                      AppStrings.partialPayment,
                    ].map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<RoomManagementViewModel>().updatePaymentType(val);
                      }
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Field 2: Payment Option Dropdown
          Text(
            AppStrings.paymentOption,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Selector<RoomManagementViewModel, String>(
            selector: (_, vm) => vm.selectedPaymentOption,
            builder: (context, selectedOption, _) {
              return Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedOption == AppStrings.selectPaymentOption ? null : selectedOption,
                    hint: Text(
                      AppStrings.selectPaymentOption,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    items: [
                      AppStrings.paymentOptionCard,
                      AppStrings.paymentOptionCheque,
                      AppStrings.paymentOptionBankTransfer,
                      AppStrings.paymentOptionUPI,
                      AppStrings.paymentOptionCash,
                    ].map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<RoomManagementViewModel>().updatePaymentOption(val);
                      }
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Field 3: Amount * Input Field
          RichText(
            text: TextSpan(
              text: 'Amount ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              children: const [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Selector<RoomManagementViewModel, String>(
            selector: (_, vm) => vm.paymentType,
            builder: (context, paymentType, _) {
              final vm = context.read<RoomManagementViewModel>();
              final isFull = paymentType == AppStrings.fullPayment;
              final isNotSelected = paymentType == AppStrings.selectPayment;
              final isLocked = isFull || isNotSelected;

              return SizedBox(
                height: 44,
                child: TextFormField(
                  controller: vm.paymentAmountController,
                 readOnly: isLocked,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isFull ? const Color(0xFF475569) : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: isLocked,
                    fillColor: isLocked ? const Color(0xFFF1F5F9) : const Color(0xFFFAFAFA),
                    hintText: isNotSelected ? AppStrings.selectPaymentFirst : null,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    suffixIcon: isFull
                        ? const Tooltip(
                            message: AppStrings.fullPaymentAmountFixed,
                            child: Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isLocked ? const Color(0xFFE5E7EB) : AppColors.primary,
                        width: isLocked ? 1 : 1.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          const SizedBox(height: 16),

          // Action Buttons: Cancel and Pay
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF1E293B), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppStrings.cancel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Selector<RoomManagementViewModel, bool>(
                  selector: (_, vm) => vm.isSubmittingPayment,
                  builder: (context, isSubmitting, _) {
                    return SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final success = await context.read<RoomManagementViewModel>().submitPayment();
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A0A0A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppStrings.submitPay,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
