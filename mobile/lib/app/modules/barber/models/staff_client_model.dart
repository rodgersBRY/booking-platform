import 'package:json_annotation/json_annotation.dart';

part 'staff_client_model.g.dart';

/// One client entry — returned both by GET /v1/staff/clients/search (an
/// existing client match) and by POST /v1/staff/clients (a freshly
/// created one). The create endpoint's response is a strict subset
/// (`preferredStaffId`/`preferredStaffName`/`isRegular` aren't part of its
/// contract), so every field beyond id/name/phone/totalVisits/lastVisitAt
/// is nullable/defaulted rather than required — one model serves both
/// call sites instead of two near-identical ones.
@JsonSerializable()
class StaffClientModel {
  final String id;
  final String name;
  final String phone;
  final String? preferredStaffId;
  final String? preferredStaffName;
  @JsonKey(defaultValue: 0)
  final int totalVisits;
  final String? lastVisitAt;
  @JsonKey(defaultValue: false)
  final bool isRegular;

  const StaffClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.preferredStaffId,
    required this.preferredStaffName,
    required this.totalVisits,
    required this.lastVisitAt,
    required this.isRegular,
  });

  factory StaffClientModel.fromJson(Map<String, dynamic> json) =>
      _$StaffClientModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffClientModelToJson(this);

  String get visitsLabel => totalVisits == 1 ? '1 visit' : '$totalVisits visits';
}
