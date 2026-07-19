import 'booking_client_info.dart';

/// GET /v1/staff/bookings/[id] — the barber's working screen for one
/// appointment. Richer than [StaffAppointmentModel] (customer contact
/// info, notes, and the canStart/canComplete workflow flags), which is
/// why the Schedule/Dashboard lists carry the lighter model and this page
/// fetches its own detail by id instead of reusing a list entry.
///
/// Also reused for the `booking` object POST /v1/staff/bookings/[id]/start
/// returns — the backend contract describes it as "the updated booking",
/// same shape as this detail response, just with a fresh scheduledStart.
class BookingDetailModel {
  final String bookingId;
  final String status;
  final String channel;
  final String scheduledStart;
  final String scheduledEnd;
  final int durationMinutes;
  final List<String> services;
  final BookingClientInfo client;

  /// `clients.staff_notes` — private, only visible to staff (never the
  /// customer). See [BookingClientInfo.customerNotes] for the
  /// customer-visible counterpart.
  final String? staffNotes;
  final bool canStart;
  final bool canComplete;

  BookingDetailModel({
    required this.bookingId,
    required this.status,
    required this.channel,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.durationMinutes,
    required this.services,
    required this.client,
    required this.staffNotes,
    required this.canStart,
    required this.canComplete,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailModel(
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
      channel: json['channel'] as String,
      scheduledStart: json['scheduledStart'] as String,
      scheduledEnd: json['scheduledEnd'] as String,
      durationMinutes: json['durationMinutes'] as int,
      services: (json['services'] as List).map((e) => e as String).toList(),
      client: BookingClientInfo.fromJson(
        json['client'] as Map<String, dynamic>,
      ),
      staffNotes: json['staffNotes'] as String?,
      canStart: json['canStart'] as bool? ?? false,
      canComplete: json['canComplete'] as bool? ?? false,
    );
  }

  String get servicesLabel => services.join(' + ');

  /// Backs optimistic updates after notes edits and the start/complete
  /// actions, mirroring StaffDayModel.copyWith. [customerNotes] updates
  /// the nested [client] record — the PATCH endpoint returns
  /// customerNotes/staffNotes as a flat pair even though customerNotes
  /// lives under `client` in this GET shape.
  BookingDetailModel copyWith({
    String? status,
    String? scheduledStart,
    String? scheduledEnd,
    String? staffNotes,
    String? customerNotes,
    bool? canStart,
    bool? canComplete,
  }) {
    return BookingDetailModel(
      bookingId: bookingId,
      status: status ?? this.status,
      channel: channel,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      durationMinutes: durationMinutes,
      services: services,
      client:
          customerNotes != null
              ? client.copyWith(customerNotes: customerNotes)
              : client,
      staffNotes: staffNotes ?? this.staffNotes,
      canStart: canStart ?? this.canStart,
      canComplete: canComplete ?? this.canComplete,
    );
  }
}
