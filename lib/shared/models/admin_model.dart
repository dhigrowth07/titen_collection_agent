/// Admin / PG Branch Domain Model
class AdminModel {
  final String id;
  final String name;

  const AdminModel({
    required this.id,
    required this.name,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: (json['admin_id'] ?? json['id'] ?? '').toString(),
      name: (json['admin_name'] ?? json['name'] ?? 'Admin').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_id': id,
      'admin_name': name,
    };
  }
}
