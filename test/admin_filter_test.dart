import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:collection_agent/modules/room_management/viewmodel/room_management_viewmodel.dart';
import 'package:collection_agent/modules/room_management/views/widgets/admin_filter_dropdown.dart';
import 'package:collection_agent/shared/models/admin_model.dart';
import 'package:collection_agent/shared/models/block_model.dart';
import 'package:collection_agent/shared/models/room_model.dart';

void main() {
  group('Admin Model and Filter Tests', () {
    test('AdminModel fromJson and toJson serialization', () {
      final json = {
        'admin_id': '6a4dc5af-ee9a-4128-a78f-dcb4b0c32330',
        'admin_name': 'Sunrise Elite PG',
      };
      final admin = AdminModel.fromJson(json);
      expect(admin.id, '6a4dc5af-ee9a-4128-a78f-dcb4b0c32330');
      expect(admin.name, 'Sunrise Elite PG');
      expect(admin.toJson()['admin_name'], 'Sunrise Elite PG');
    });

    test('BlockModel and RoomModel retain adminId and adminName', () {
      const block = BlockModel(
        id: '1',
        name: 'Block A',
        adminId: 'admin-1',
        adminName: 'Sunrise PG',
        totalRooms: 5,
        totalBeds: 10,
        occupiedBeds: 8,
      );
      expect(block.adminId, 'admin-1');
      expect(block.adminName, 'Sunrise PG');

      const room = RoomModel(
        id: 'r1',
        roomNumber: '101',
        blockId: '1',
        adminId: 'admin-1',
        adminName: 'Sunrise PG',
        beds: [],
      );
      expect(room.adminId, 'admin-1');
      expect(room.adminName, 'Sunrise PG');
    });

    testWidgets('AdminFilterDropdown renders correctly with All Admins', (WidgetTester tester) async {
      final vm = RoomManagementViewModel(autoLoad: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<RoomManagementViewModel>.value(
              value: vm,
              child: const SizedBox(
                width: 200,
                child: AdminFilterDropdown(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AdminFilterDropdown), findsOneWidget);
      expect(find.text('All Admins'), findsOneWidget);
    });
  });
}
