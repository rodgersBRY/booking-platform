// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotModel _$SlotModelFromJson(Map<String, dynamic> json) => SlotModel(
  start: json['start'] as String,
  end: json['end'] as String,
  label: json['label'] as String,
  staffId: json['staffId'] as String,
);

Map<String, dynamic> _$SlotModelToJson(SlotModel instance) => <String, dynamic>{
  'start': instance.start,
  'end': instance.end,
  'label': instance.label,
  'staffId': instance.staffId,
};
