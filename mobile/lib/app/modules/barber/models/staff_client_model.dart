/// One client entry — returned both by GET /v1/staff/clients/search (an
/// existing client match) and by POST /v1/staff/clients (a freshly
/// created one). The create endpoint's response is a strict subset
/// (`preferredStaffId`/`preferredStaffName`/`isRegular` aren't part of its
/// contract), so every field beyond id/name/phone/totalVisits/lastVisitAt
/// is nullable/defaulted rather than required — one model serves both
/// call sites instead of two near-identical ones.
class StaffClientModel {
  final String id;
  final String name;
  final String phone;
  final String? preferredStaffId;
  final String? preferredStaffName;
  final int totalVisits;
  final String? lastVisitAt;
  final bool isRegular;

  StaffClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.preferredStaffId,
    required this.preferredStaffName,
    required this.totalVisits,
    required this.lastVisitAt,
    required this.isRegular,
  });

  factory StaffClientModel.fromJson(Map<String, dynamic> json) {
    return StaffClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      preferredStaffId: json['preferredStaffId'] as String?,
      preferredStaffName: json['preferredStaffName'] as String?,
      totalVisits: json['totalVisits'] as int? ?? 0,
      lastVisitAt: json['lastVisitAt'] as String?,
      isRegular: json['isRegular'] as bool? ?? false,
    );
  }

  String get visitsLabel => totalVisits == 1 ? '1 visit' : '$totalVisits visits';
}
