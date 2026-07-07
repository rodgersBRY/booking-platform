class BarberModel {
  final String id;
  final String name;

  BarberModel({required this.id, required this.name});

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    return BarberModel(id: json['id'] as String, name: json['name'] as String);
  }
}
