class SlotModel {
  final String start;
  final String end;
  final String label;
  final String barberId;

  SlotModel({
    required this.start,
    required this.end,
    required this.label,
    required this.barberId,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      start: json['start'] as String,
      end: json['end'] as String,
      label: json['label'] as String,
      barberId: json['barberId'] as String,
    );
  }
}
