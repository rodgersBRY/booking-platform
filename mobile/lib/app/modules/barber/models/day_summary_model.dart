/// Today's appointment counts — the Dashboard's "Today's Summary" tile.
class DaySummaryModel {
  final int total;
  final int completed;
  final int remaining;

  DaySummaryModel({
    required this.total,
    required this.completed,
    required this.remaining,
  });

  factory DaySummaryModel.fromJson(Map<String, dynamic> json) {
    return DaySummaryModel(
      total: json['total'] as int,
      completed: json['completed'] as int,
      remaining: json['remaining'] as int,
    );
  }
}
