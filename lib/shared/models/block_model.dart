/// Block Domain Model
class BlockModel {
  final String id;
  final String name;
  final String? adminId;
  final String? adminName;
  final int totalRooms;
  final int totalBeds;
  final int occupiedBeds;

  const BlockModel({
    required this.id,
    required this.name,
    this.adminId,
    this.adminName,
    required this.totalRooms,
    required this.totalBeds,
    required this.occupiedBeds,
  });

  int get vacantBeds => totalBeds - occupiedBeds;

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      id: json['id'] as String? ?? json['block_id']?.toString() ?? '',
      name: json['name'] as String? ?? json['block_name']?.toString() ?? '',
      adminId: json['admin_id']?.toString() ?? json['adminId']?.toString(),
      adminName: json['admin_name']?.toString() ?? json['adminName']?.toString(),
      totalRooms: json['totalRooms'] as int? ?? json['total_rooms'] as int? ?? 0,
      totalBeds: json['totalBeds'] as int? ?? json['total_beds'] as int? ?? 0,
      occupiedBeds: json['occupiedBeds'] as int? ?? json['occupied_beds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'admin_id': adminId,
      'admin_name': adminName,
      'totalRooms': totalRooms,
      'totalBeds': totalBeds,
      'occupiedBeds': occupiedBeds,
    };
  }

  BlockModel copyWith({
    String? id,
    String? name,
    String? adminId,
    String? adminName,
    int? totalRooms,
    int? totalBeds,
    int? occupiedBeds,
  }) {
    return BlockModel(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      totalRooms: totalRooms ?? this.totalRooms,
      totalBeds: totalBeds ?? this.totalBeds,
      occupiedBeds: occupiedBeds ?? this.occupiedBeds,
    );
  }
}
