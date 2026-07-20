import 'package:json_annotation/json_annotation.dart';

part 'slot_model.g.dart';

@JsonSerializable()
class SlotModel {
  final String start;
  final String end;
  final String label;
  final String staffId;

  const SlotModel({
    required this.start,
    required this.end,
    required this.label,
    required this.staffId,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) =>
      _$SlotModelFromJson(json);

  Map<String, dynamic> toJson() => _$SlotModelToJson(this);
}
