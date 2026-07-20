import 'package:json_annotation/json_annotation.dart';

part 'staff_notification_model.g.dart';

/// One entry in GET /v1/staff/notifications — booking lifecycle events
/// (created/cancelled/rescheduled/checked-in) for bookings assigned to the
/// signed-in staff member, per Slice 6 of
/// docs/superpowers/specs/2026-07-18-barber-workspace-design.md.
///
/// [readAt] is null while unread, an ISO8601 string once read — mirrors
/// the customer module's NotificationModel except that module models
/// read/unread as a bare bool (`read`); the staff endpoint hands back the
/// timestamp itself, so this model keeps it rather than collapsing it to
/// a bool the way the customer side does.
@JsonSerializable()
class StaffNotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? bookingId;
  final String? readAt;
  final String createdAt;

  const StaffNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.bookingId,
    required this.readAt,
    required this.createdAt,
  });

  factory StaffNotificationModel.fromJson(Map<String, dynamic> json) =>
      _$StaffNotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffNotificationModelToJson(this);

  bool get isUnread => readAt == null;

  /// Returns a copy stamped as read at [timestamp] — used for the
  /// notifications list's optimistic tap-to-read update.
  StaffNotificationModel markedRead(String timestamp) => StaffNotificationModel(
    id: id,
    type: type,
    title: title,
    body: body,
    bookingId: bookingId,
    readAt: timestamp,
    createdAt: createdAt,
  );
}
