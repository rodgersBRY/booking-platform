// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_appointment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffAppointmentModel _$StaffAppointmentModelFromJson(
  Map<String, dynamic> json,
) => StaffAppointmentModel(
  bookingId: json['bookingId'] as String,
  clientName: json['clientName'] as String,
  services:
      (json['services'] as List<dynamic>).map((e) => e as String).toList(),
  scheduledStart: json['scheduledStart'] as String,
  scheduledEnd: json['scheduledEnd'] as String,
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  status: json['status'] as String,
  channel: json['channel'] as String,
);

Map<String, dynamic> _$StaffAppointmentModelToJson(
  StaffAppointmentModel instance,
) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'clientName': instance.clientName,
  'services': instance.services,
  'scheduledStart': instance.scheduledStart,
  'scheduledEnd': instance.scheduledEnd,
  'durationMinutes': instance.durationMinutes,
  'status': instance.status,
  'channel': instance.channel,
};
