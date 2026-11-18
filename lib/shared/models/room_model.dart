import 'package:collection_agent/shared/models/bed_model.dart';

/// Room Domain Model
class RoomModel {
  final String id;
  final String roomNumber;
  final String blockId;
  final String? adminId;
  final String? adminName;
  final List<BedModel> beds;

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.blockId,
    this.adminId,
    this.adminName,
    required this.beds,
  });

  int get totalBeds => beds.length;
  int get occupiedBeds => beds.where((b) => !b.isVacant).length;
  int get vacantBeds => beds.where((b) => b.isVacant).length;

  double get totalAmount => beds.fold(0.0, (sum, b) => sum + b.totalAmount);
  double get paidAmount => beds.fold(0.0, (sum, b) => sum + b.paidAmount);
  double get remainingAmount => beds.fold(0.0, (sum, b) => sum + b.remainingAmount);

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String? ?? json['room_id']?.toString() ?? '',
      roomNumber: json['roomNumber'] as String? ?? json['room_number']?.toString() ?? '',
      blockId: json['blockId'] as String? ?? json['block_id']?.toString() ?? '',
      adminId: json['admin_id']?.toString() ?? json['adminId']?.toString(),
      adminName: json['admin_name']?.toString() ?? json['adminName']?.toString(),
      beds: (json['beds'] as List<dynamic>?)
              ?.map((e) => BedModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'blockId': blockId,
      'admin_id': adminId,
      'admin_name': adminName,
      'beds': beds.map((b) => b.toJson()).toList(),
    };
  }

  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? blockId,
    String? adminId,
    String? adminName,
    List<BedModel>? beds,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      blockId: blockId ?? this.blockId,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      beds: beds ?? this.beds,
    );
  }
}
