// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
  id: json['id'] as String,
  status: json['status'] as String,
  channel: json['channel'] as String,
  scheduledStart: json['scheduledStart'] as String,
  scheduledEnd: json['scheduledEnd'] as String,
  service:
      json['service'] == null
          ? null
          : ServiceModel.fromJson(json['service'] as Map<String, dynamic>),
  staff:
      json['staff'] == null
          ? null
          : StaffModel.fromJson(json['staff'] as Map<String, dynamic>),
  canCancel: json['canCancel'] as bool,
  canReschedule: json['canReschedule'] as bool,
);

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'channel': instance.channel,
      'scheduledStart': instance.scheduledStart,
      'scheduledEnd': instance.scheduledEnd,
      'service': instance.service,
      'staff': instance.staff,
      'canCancel': instance.canCancel,
      'canReschedule': instance.canReschedule,
    };
