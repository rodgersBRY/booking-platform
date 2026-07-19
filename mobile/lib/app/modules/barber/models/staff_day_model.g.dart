// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_day_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffDayModel _$StaffDayModelFromJson(
  Map<String, dynamic> json,
) => StaffDayModel(
  staffId: json['staffId'] as String,
  presence: StaffPresence.fromJson(json['presence'] as String),
  presenceUpdatedAt: json['presenceUpdatedAt'] as String?,
  workingHours:
      json['workingHours'] == null
          ? null
          : WorkingHoursModel.fromJson(
            json['workingHours'] as Map<String, dynamic>,
          ),
  summary: DaySummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
  nextAppointment:
      json['nextAppointment'] == null
          ? null
          : StaffAppointmentModel.fromJson(
            json['nextAppointment'] as Map<String, dynamic>,
          ),
  schedule:
      (json['schedule'] as List<dynamic>)
          .map((e) => StaffAppointmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$StaffDayModelToJson(StaffDayModel instance) =>
    <String, dynamic>{
      'staffId': instance.staffId,
      'presence': StaffPresence.toJsonValue(instance.presence),
      'presenceUpdatedAt': instance.presenceUpdatedAt,
      'workingHours': instance.workingHours,
      'summary': instance.summary,
      'nextAppointment': instance.nextAppointment,
      'schedule': instance.schedule,
    };
