/// One appointment entry from GET /v1/staff/day — used for both
/// `nextAppointment` and each row in `schedule` (the same shape appears
/// in both places; `nextAppointment` is also present inside `schedule`).
class StaffAppointmentModel {
  final String bookingId;
  final String clientName;
  final List<String> services;
  final String scheduledStart;
  final String scheduledEnd;
  final int durationMinutes;
  final String status;
  final String channel;

  StaffAppointmentModel({
    required this.bookingId,
    required this.clientName,
    required this.services,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.durationMinutes,
    required this.status,
    required this.channel,
  });

  factory StaffAppointmentModel.fromJson(Map<String, dynamic> json) {
    return StaffAppointmentModel(
      bookingId: json['bookingId'] as String,
      clientName: json['clientName'] as String,
      services: (json['services'] as List).map((e) => e as String).toList(),
      scheduledStart: json['scheduledStart'] as String,
      scheduledEnd: json['scheduledEnd'] as String,
      durationMinutes: json['durationMinutes'] as int,
      status: json['status'] as String,
      channel: json['channel'] as String,
    );
  }

  /// "Haircut" + "Beard Trim" -> "Haircut + Beard Trim", matching
  /// BARBER-APP.md's next-appointment example.
  String get servicesLabel => services.join(' + ');
}
