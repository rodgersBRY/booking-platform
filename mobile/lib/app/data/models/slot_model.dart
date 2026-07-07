class SlotModel {
  final String start;
  final String end;
  final String label;

  /// The staff member free for this slot. Wire key is still "barberId" —
  /// the backend only has a barber role today.
  final String staffId;

  SlotModel({
    required this.start,
    required this.end,
    required this.label,
    required this.staffId,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      start: json['start'] as String,
      end: json['end'] as String,
      label: json['label'] as String,
      staffId: json['barberId'] as String,
    );
  }
}
