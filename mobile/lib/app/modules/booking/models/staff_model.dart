import 'package:json_annotation/json_annotation.dart';

part 'staff_model.g.dart';

/// A bookable staff member — barber, beautician, or masseuse.
@JsonSerializable()
class StaffModel {
  final String id;
  final String name;
  final String role;
  final String? avatarUrl;

  const StaffModel({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) =>
      _$StaffModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffModelToJson(this);
}
