import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:collection_agent/core/constants/app_colors.dart';
import 'package:collection_agent/core/constants/app_strings.dart';
import 'package:collection_agent/core/theme/app_text_styles.dart';
import 'package:collection_agent/modules/room_management/viewmodel/room_management_viewmodel.dart';
import 'package:collection_agent/shared/models/tenant_model.dart';
import 'package:collection_agent/shared/views/document_viewer_screen.dart';

/// Screen 4: Customer Details & KYC Modal Bottom Sheet
/// STRICT RULE: Public StatelessWidget, matches Screen 4 pixel-perfect
class CustomerDetailsBottomSheet extends StatelessWidget {
  final TenantModel tenant;

  const CustomerDetailsBottomSheet({
    super.key,
    required this.tenant,
  });

  static void show(BuildContext context, TenantModel tenant, [RoomManagementViewModel? viewModel]) {
    RoomManagementViewModel? vm;
    try {
      vm = viewModel ?? context.read<RoomManagementViewModel>();
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        if (vm != null) {
          return ChangeNotifierProvider.value(
            value: vm,
            child: CustomerDetailsBottomSheet(tenant: tenant),
          );
        }
        return CustomerDetailsBottomSheet(tenant: tenant);
      },
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  String _formatDate(String rawDate) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return 'Not Provided';
    }
    try {
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final day = parsed.day.toString().padLeft(2, '0');
        final month = months[parsed.month - 1];
        final year = parsed.year.toString();
        return '$day $month $year';
      }
    } catch (_) {}
    return trimmed;
  }

  String _formatGender(String rawGender) {
    final g = rawGender.trim();
    if (g.isEmpty || g.toLowerCase() == 'null') return 'Not Provided';
    return g[0].toUpperCase() + g.substring(1).toLowerCase();
  }

  Widget _buildTextValue(String? val) {
    final s = val?.trim() ?? '';
    final isEmpty = s.isEmpty || s.toLowerCase() == 'null' || s.toLowerCase() == 'not provided';
    return Text(
      isEmpty ? 'Not Provided' : s,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isEmpty ? AppColors.textMuted : AppColors.textPrimary,
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  Widget _buildAvatar([TenantModel? t]) {
    final activeTenant = t ?? tenant;
    final url = activeTenant.profileImageUrl?.trim();
    if (url != null && url.isNotEmpty && url.toLowerCase() != 'null') {
      return ClipOval(
        child: Image.network(
          url,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(activeTenant),
        ),
      );
    }
    return _buildInitialsAvatar(activeTenant);
  }

  Widget _buildInitialsAvatar([TenantModel? t]) {
    final activeTenant = t ?? tenant;
    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        activeTenant.initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildIdProofsList(List<String> proofs, BuildContext context) {
    if (proofs.isEmpty) {
      return Text(
        'No ID proofs uploaded',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: proofs.asMap().entries.map((entry) {
        final index = entry.key;
        final url = entry.value;
        final isPdf = url.toLowerCase().contains('.pdf');
        final isImage = url.toLowerCase().contains('.png') ||
            url.toLowerCase().contains('.jpg') ||
            url.toLowerCase().contains('.jpeg') ||
            url.toLowerCase().contains('.webp');

        final iconData = isPdf
            ? Icons.picture_as_pdf_outlined
            : (isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined);
        final iconColor = isPdf
            ? const Color(0xFFE53935)
            : (isImage ? const Color(0xFF1E88E5) : AppColors.primary);

        String title;
        try {
          final uri = Uri.parse(url);
          final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
          if (filename.isNotEmpty) {
            final ext = filename.contains('.') ? '.${filename.split('.').last}' : '';
            title = 'Document ${index + 1} ($ext)';
          } else {
            title = 'Document ${index + 1}';
          }
        } catch (_) {
          title = 'Document ${index + 1}';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Get.to(() => DocumentViewerScreen(
                  url: url,
                  title: title,
                  subtitle: tenant.name,
                ));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(iconData, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.view,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    RoomManagementViewModel? vm;
    try {
      vm = context.watch<RoomManagementViewModel?>();
    } catch (_) {}

    final liveTenant = (vm != null &&
            vm.activeTenantForDetails != null &&
            (vm.activeTenantForDetails!.id == tenant.id ||
                (tenant.userId != null && vm.activeTenantForDetails!.userId == tenant.userId)))
        ? vm.activeTenantForDetails!
        : tenant;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: AppStrings.customerDetailsPrefix,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                    children: [
                      TextSpan(
                        text: liveTenant.name,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 22, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Center Profile Avatar
                  _buildAvatar(liveTenant),
                  const SizedBox(height: 16),
                  // Payment Profile Card (Screens 4: Last month fee & payment profile)
                  _buildPaymentProfileCard(liveTenant),
                  // Key-Value Table Container
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      children: [
                        _buildTableRow(
                          icon: Icons.person_outline,
                          label: AppStrings.labelName,
                          valueWidget: _buildTextValue(liveTenant.name),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          label: AppStrings.labelCustomerId,
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.purpleBadgeLight,
                              border: Border.all(color: AppColors.purpleBadge.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              liveTenant.customerId,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.purpleBadge,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.mail_outline,
                          label: AppStrings.labelEmail,
                          valueWidget: _buildTextValue(liveTenant.email),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.phone_outlined,
                          label: AppStrings.labelPhone,
                          valueWidget: _buildTextValue(liveTenant.phone),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.calendar_today_outlined,
                          label: AppStrings.labelDob,
                          valueWidget: _buildTextValue(_formatDate(liveTenant.dob)),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.calendar_today_outlined,
                          label: AppStrings.labelJoiningDate,
                          valueWidget: _buildTextValue(_formatDate(liveTenant.joiningDate)),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.people_outline,
                          label: AppStrings.labelGender,
                          valueWidget: _buildTextValue(_formatGender(liveTenant.gender)),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.badge_outlined,
                          label: AppStrings.labelIdProofs,
                          valueWidget: _buildIdProofsList(liveTenant.idProofs, context),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.contact_phone_outlined,
                          label: AppStrings.labelEmergencyContact1,
                          valueWidget: _buildTextValue(liveTenant.emergencyContact1),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.contact_phone_outlined,
                          label: AppStrings.labelEmergencyContact2,
                          valueWidget: _buildTextValue(liveTenant.emergencyContact2),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          icon: Icons.home_outlined,
                          label: AppStrings.labelRoom,
                          valueWidget: Text(
                            '${liveTenant.roomNumber} (${liveTenant.blockName})',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        _buildDivider(),
                        _buildTableRow(
                          label: AppStrings.labelStatus,
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              border: Border.all(color: AppColors.success),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              liveTenant.status,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProfileCard(TenantModel t) {
    final hasLastMonth = t.hasLastMonthPending;
    final lastMonthAmt = t.lastMonthPendingAmount;
    final currentDue = t.dueAmount;
    final totalDue = t.combinedOutstandingDue;
    final cycles = t.recentCycles;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  AppStrings.paymentProfile,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: totalDue > 0 ? const Color(0xFFFEF2F2) : AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: totalDue > 0 ? const Color(0xFFEF4444) : AppColors.success,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    totalDue > 0 ? 'Total Due: ${_formatCurrency(totalDue)}' : 'Settled',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: totalDue > 0 ? const Color(0xFFDC2626) : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending Last Month Payment banner / badge
                if (hasLastMonth) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDBA74), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFEA580C),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.pendingLastMonthPayment,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9A3412),
                                ),
                              ),
                              if (t.lastMonthCycle.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  t.lastMonthCycle,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 11,
                                    color: const Color(0xFFC2410C),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(lastMonthAmt),
                          style: AppTextStyles.titleSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFC2410C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.allPreviousCyclesSettled,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Current Month & Total Breakdown Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.currentMonthRent,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              currentDue > 0 ? _formatCurrency(currentDue) : 'Settled',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: currentDue > 0 ? AppColors.textPrimary : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.totalOutstandingDue,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              totalDue > 0 ? _formatCurrency(totalDue) : '₹0',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: totalDue > 0 ? const Color(0xFFDC2626) : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Billing Cycle History
                if (cycles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.cycleHistory,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...cycles.take(4).map((c) {
                    final isDueCycle = c.dueAmount > 0;
                    final statusText = c.status.isNotEmpty ? c.status.toUpperCase() : (isDueCycle ? 'DUE' : 'PAID');
                    final statusColor = (statusText == 'PAID' || !isDueCycle)
                        ? AppColors.success
                        : (c.isPastCycle ? const Color(0xFFDC2626) : const Color(0xFFD97706));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.cycleName.isNotEmpty ? c.cycleName : 'Cycle',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (c.isPastCycle && isDueCycle)
                                  Text(
                                    AppStrings.lastMonthFee,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            isDueCycle ? 'Due: ${_formatCurrency(c.dueAmount)}' : 'Paid: ${_formatCurrency(c.paidAmount)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: isDueCycle ? const Color(0xFFDC2626) : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    IconData? icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.border, height: 1, thickness: 1);
  }
}
