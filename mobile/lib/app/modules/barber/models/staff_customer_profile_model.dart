import 'package:json_annotation/json_annotation.dart';

import 'customer_visit_entry.dart';

part 'staff_customer_profile_model.g.dart';

/// GET /v1/staff/clients/[id] — the barber's "Customer Profile" screen:
/// contact info, this staff member's visit count and timeline with the
/// client, and both note fields. The endpoint 403/404s if this staff
/// member never served the client (see
/// StaffCustomerProfileResult.notServed), so every instance of this model
/// that exists client-side represents a client the signed-in barber has
/// actually worked on.
@JsonSerializable()
class StaffCustomerProfileModel {
  final String id;
  final String name;
  final String phone;
  final int visitCount;

  /// `clients.customer_notes` — visible to staff, same field
  /// BookingClientInfo.customerNotes surfaces on the appointment detail
  /// screen. Read-only on this screen: Slice 5's backend contract has no
  /// PATCH endpoint for the customer-profile page (only
  /// PATCH /v1/staff/bookings/[id] edits notes, scoped to one booking).
  final String? customerNotes;

  /// `clients.staff_notes` — private, staff-only. Read-only here for the
  /// same reason as [customerNotes].
  final String? staffNotes;

  @JsonKey(defaultValue: <CustomerVisitEntry>[])
  final List<CustomerVisitEntry> visits;

  const StaffCustomerProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.visitCount,
    required this.customerNotes,
    required this.staffNotes,
    required this.visits,
  });

  factory StaffCustomerProfileModel.fromJson(Map<String, dynamic> json) =>
      _$StaffCustomerProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffCustomerProfileModelToJson(this);

  String get visitCountLabel => visitCount == 1 ? '1 Visit' : '$visitCount Visits';
}
