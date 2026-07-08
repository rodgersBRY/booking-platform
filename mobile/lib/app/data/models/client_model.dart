class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int loyaltyPoints;
  final int totalVisits;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.loyaltyPoints,
    required this.totalVisits,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      loyaltyPoints: json['loyaltyPoints'] as int,
      totalVisits: json['totalVisits'] as int,
    );
  }
}
