// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffNotificationModel _$StaffNotificationModelFromJson(
  Map<String, dynamic> json,
) => StaffNotificationModel(
  id: json['id'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  bookingId: json['bookingId'] as String?,
  readAt: json['readAt'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$StaffNotificationModelToJson(
  StaffNotificationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'title': instance.title,
  'body': instance.body,
  'bookingId': instance.bookingId,
  'readAt': instance.readAt,
  'createdAt': instance.createdAt,
};
