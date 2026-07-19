import 'package:json_annotation/json_annotation.dart';

part 'day_summary_model.g.dart';

/// Today's appointment counts — the Dashboard's "Today's Summary" tile.
@JsonSerializable()
class DaySummaryModel {
  final int total;
  final int completed;
  final int remaining;

  const DaySummaryModel({
    required this.total,
    required this.completed,
    required this.remaining,
  });

  factory DaySummaryModel.fromJson(Map<String, dynamic> json) =>
      _$DaySummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$DaySummaryModelToJson(this);
}
