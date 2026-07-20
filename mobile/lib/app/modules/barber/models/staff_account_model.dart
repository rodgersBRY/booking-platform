import 'package:json_annotation/json_annotation.dart';

part 'staff_account_model.g.dart';

/// The authenticated staff member's own account.
///
/// Distinct from [StaffModel] (`staff_model.dart`), which is the
/// read-only shape returned when listing bookable staff in the customer
/// booking flow. That endpoint intentionally exposes only `id`, `name`,
/// `role`, and `avatarUrl` — public booking data. This model backs
/// `/v1/staff/login` and `/v1/staff/me`, a private account record that
/// also carries `phone`, `email`, and `status`. Keeping them separate
/// means the two endpoints can evolve independently without either one
/// leaking fields the other shouldn't have.
@JsonSerializable()
class StaffAccountModel {
  final String id;
  final String name;
  final String role;
  final String phone;
  final String email;
  final String? avatarUrl;
  final String status;

  const StaffAccountModel({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.status,
  });

  factory StaffAccountModel.fromJson(Map<String, dynamic> json) =>
      _$StaffAccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffAccountModelToJson(this);
}
