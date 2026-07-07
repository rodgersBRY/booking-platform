/// A bookable staff member — barbers today, but the backend's staff table
/// also covers receptionist/beautician/masseuse roles, so this stays generic
/// on the app side even though today's API only ever returns barbers.
class StaffModel {
  final String id;
  final String name;

  StaffModel({required this.id, required this.name});

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(id: json['id'] as String, name: json['name'] as String);
  }
}
