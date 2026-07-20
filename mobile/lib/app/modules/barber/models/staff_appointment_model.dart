import 'package:json_annotation/json_annotation.dart';

part 'staff_appointment_model.g.dart';

/// One appointment entry from GET /v1/staff/day — used for both
/// `nextAppointment` and each row in `schedule` (the same shape appears
/// in both places; `nextAppointment` is also present inside `schedule`).
@JsonSerializable()
class StaffAppointmentModel {
  final String bookingId;
  final String clientName;
  final List<String> services;
  final String scheduledStart;
  final String scheduledEnd;
  final int durationMinutes;
  final String status;
  final String channel;

  const StaffAppointmentModel({
    required this.bookingId,
    required this.clientName,
    required this.services,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.durationMinutes,
    required this.status,
    required this.channel,
  });

  factory StaffAppointmentModel.fromJson(Map<String, dynamic> json) =>
      _$StaffAppointmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffAppointmentModelToJson(this);

  /// "Haircut" + "Beard Trim" -> "Haircut + Beard Trim", matching
  /// BARBER-APP.md's next-appointment example.
  String get servicesLabel => services.join(' + ');
}
