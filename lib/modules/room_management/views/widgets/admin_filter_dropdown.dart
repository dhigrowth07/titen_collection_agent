import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection_agent/core/constants/app_colors.dart';
import 'package:collection_agent/core/constants/app_strings.dart';
import 'package:collection_agent/core/theme/app_text_styles.dart';
import 'package:collection_agent/modules/room_management/viewmodel/room_management_viewmodel.dart';
import 'package:collection_agent/shared/models/admin_model.dart';

/// Admin / Property Filter Dropdown Button
/// Allows collection agent to switch between specific Admin/PG branches or view All Admins
class AdminFilterDropdown extends StatelessWidget {
  const AdminFilterDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<RoomManagementViewModel, (String, List<AdminModel>)>(
      selector: (_, vm) => (vm.selectedAdminId, vm.admins),
      builder: (context, data, _) {
        final selectedId = data.$1;
        final admins = data.$2;
        final vm = context.read<RoomManagementViewModel>();

        return PopupMenuButton<String>(
          tooltip: 'Filter by Admin / PG Branch',
          onSelected: (adminId) {
            vm.filterAdmin(adminId);
          },
          itemBuilder: (context) {
            return [
              const PopupMenuItem<String>(
                value: 'ALL',
                child: Row(
                  children: [
                    Icon(Icons.domain_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(AppStrings.allAdmins),
                  ],
                ),
              ),
              ...admins.map(
                (a) => PopupMenuItem<String>(
                  value: a.id,
                  child: Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.business_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedId == 'ALL'
                        ? AppStrings.allAdmins
                        : (admins.firstWhere(
                            (a) => a.id == selectedId,
                            orElse: () => const AdminModel(id: '', name: 'Admin'),
                          ).name),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
