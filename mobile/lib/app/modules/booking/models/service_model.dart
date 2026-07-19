class ServiceModel {
  final String id;
  final String name;
  final String? category;
  final int durationMinutes;
  final num price;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.price,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      durationMinutes: json['durationMinutes'] as int,
      price: json['price'] as num,
    );
  }

  String get formattedPrice => 'KSh ${price.round()}';

  String get formattedDuration {
    if (durationMinutes < 60) return '$durationMinutes min';
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return minutes > 0 ? '$hours hr $minutes min' : '$hours hr';
  }
}
