import 'package:json_annotation/json_annotation.dart';

import 'booking_client_info.dart';

part 'booking_detail_model.g.dart';

/// GET /v1/staff/bookings/[id] — the barber's working screen for one
/// appointment. Richer than [StaffAppointmentModel] (customer contact
/// info, notes, and the canStart/canComplete workflow flags), which is
/// why the Schedule/Dashboard lists carry the lighter model and this page
/// fetches its own detail by id instead of reusing a list entry.
///
/// Also reused for the `booking` object POST /v1/staff/bookings/[id]/start
/// returns — the backend contract describes it as "the updated booking",
/// same shape as this detail response, just with a fresh scheduledStart.
@JsonSerializable()
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
  @JsonKey(defaultValue: false)
  final bool canStart;
  @JsonKey(defaultValue: false)
  final bool canComplete;

  const BookingDetailModel({
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

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingDetailModelToJson(this);

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
