import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'working_hours_model.g.dart';

/// The staff member's working hours for the requested day, sourced from
/// `staff_availability` server-side. Null on the day payload means no
/// schedule is configured for that day.
@JsonSerializable()
class WorkingHoursModel {
  final String start;
  final String end;

  const WorkingHoursModel({required this.start, required this.end});

  factory WorkingHoursModel.fromJson(Map<String, dynamic> json) =>
      _$WorkingHoursModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkingHoursModelToJson(this);

  /// "09:00" -> "9:00 AM". Falls back to the raw string if it isn't a
  /// parseable HH:mm — defensive only, the backend always sends HH:mm.
  static String _format(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return hhmm;
    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
  }

  String get formattedRange => '${_format(start)} - ${_format(end)}';
}
