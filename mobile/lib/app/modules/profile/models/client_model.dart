import 'package:json_annotation/json_annotation.dart';

part 'client_model.g.dart';

@JsonSerializable()
class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int loyaltyPoints;
  final int totalVisits;

  const ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.loyaltyPoints,
    required this.totalVisits,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) =>
      _$ClientModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClientModelToJson(this);
}
