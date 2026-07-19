import 'day_summary_model.dart';
import 'staff_appointment_model.dart';
import 'staff_presence.dart';
import 'working_hours_model.dart';

/// GET /v1/staff/day — the signed-in barber's "today" view: presence,
/// today's working hours, appointment counts, the next appointment, and
/// the full day's schedule (which still includes the next appointment).
class StaffDayModel {
  final String staffId;
  final StaffPresence presence;
  final String? presenceUpdatedAt;
  final WorkingHoursModel? workingHours;
  final DaySummaryModel summary;
  final StaffAppointmentModel? nextAppointment;
  final List<StaffAppointmentModel> schedule;

  StaffDayModel({
    required this.staffId,
    required this.presence,
    required this.presenceUpdatedAt,
    required this.workingHours,
    required this.summary,
    required this.nextAppointment,
    required this.schedule,
  });

  factory StaffDayModel.fromJson(Map<String, dynamic> json) {
    return StaffDayModel(
      staffId: json['staffId'] as String,
      presence: StaffPresence.fromJson(json['presence'] as String),
      presenceUpdatedAt: json['presenceUpdatedAt'] as String?,
      workingHours:
          json['workingHours'] != null
              ? WorkingHoursModel.fromJson(
                json['workingHours'] as Map<String, dynamic>,
              )
              : null,
      summary: DaySummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      nextAppointment:
          json['nextAppointment'] != null
              ? StaffAppointmentModel.fromJson(
                json['nextAppointment'] as Map<String, dynamic>,
              )
              : null,
      schedule:
          (json['schedule'] as List)
              .map(
                (e) =>
                    StaffAppointmentModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Backs the optimistic presence update in
  /// BarberDashboardController.changePresence — swaps presence in place
  /// instead of refetching the whole day payload.
  StaffDayModel copyWith({StaffPresence? presence, String? presenceUpdatedAt}) {
    return StaffDayModel(
      staffId: staffId,
      presence: presence ?? this.presence,
      presenceUpdatedAt: presenceUpdatedAt ?? this.presenceUpdatedAt,
      workingHours: workingHours,
      summary: summary,
      nextAppointment: nextAppointment,
      schedule: schedule,
    );
  }

  /// The "Remaining Schedule" timeline: everything except the next
  /// appointment (which gets its own larger card above it) and anything
  /// already completed.
  List<StaffAppointmentModel> get remainingSchedule {
    return schedule
        .where(
          (a) =>
              a.bookingId != nextAppointment?.bookingId &&
              a.status != 'completed',
        )
        .toList();
  }
}
