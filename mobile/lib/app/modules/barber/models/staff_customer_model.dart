import 'package:json_annotation/json_annotation.dart';

part 'staff_customer_model.g.dart';

/// One entry in GET /v1/staff/clients — a client the signed-in staff
/// member has personally served. [visitCount]/[lastVisitAt] are scoped to
/// *this* barber's own history with the client, not the client's
/// shop-wide totals — distinct from StaffClientModel.totalVisits (used by
/// the create-booking wizard's global `/v1/staff/clients/search`), which
/// counts visits across every staff member. Don't conflate the two even
/// though the field names are similar.
@JsonSerializable()
class StaffCustomerModel {
  final String id;
  final String name;
  final String phone;
  final int visitCount;
  final String lastVisitAt;

  const StaffCustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.visitCount,
    required this.lastVisitAt,
  });

  factory StaffCustomerModel.fromJson(Map<String, dynamic> json) =>
      _$StaffCustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffCustomerModelToJson(this);

  String get visitCountLabel => visitCount == 1 ? '1 Visit' : '$visitCount Visits';
}
