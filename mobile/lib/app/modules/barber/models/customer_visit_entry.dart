import 'package:json_annotation/json_annotation.dart';

part 'customer_visit_entry.g.dart';

/// One row in GET /v1/staff/clients/[id]'s `visits` timeline — a past
/// visit's date and the services performed, scoped to this staff member's
/// own history with the client (same per-barber scoping as
/// StaffCustomerModel).
@JsonSerializable()
class CustomerVisitEntry {
  final String date;
  final List<String> services;

  const CustomerVisitEntry({required this.date, required this.services});

  factory CustomerVisitEntry.fromJson(Map<String, dynamic> json) =>
      _$CustomerVisitEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerVisitEntryToJson(this);

  String get servicesLabel => services.join(' + ');
}
