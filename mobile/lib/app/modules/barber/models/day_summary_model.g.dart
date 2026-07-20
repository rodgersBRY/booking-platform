// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DaySummaryModel _$DaySummaryModelFromJson(Map<String, dynamic> json) =>
    DaySummaryModel(
      total: (json['total'] as num).toInt(),
      completed: (json['completed'] as num).toInt(),
      remaining: (json['remaining'] as num).toInt(),
    );

Map<String, dynamic> _$DaySummaryModelToJson(DaySummaryModel instance) =>
    <String, dynamic>{
      'total': instance.total,
      'completed': instance.completed,
      'remaining': instance.remaining,
    };
