/// A bookable staff member — barber, beautician, or masseuse.
class StaffModel {
  final String id;
  final String name;
  final String role;

  StaffModel({required this.id, required this.name, required this.role});

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }
}
