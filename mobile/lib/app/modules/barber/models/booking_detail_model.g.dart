// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingDetailModel _$BookingDetailModelFromJson(Map<String, dynamic> json) =>
    BookingDetailModel(
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
      channel: json['channel'] as String,
      scheduledStart: json['scheduledStart'] as String,
      scheduledEnd: json['scheduledEnd'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      services:
          (json['services'] as List<dynamic>).map((e) => e as String).toList(),
      client: BookingClientInfo.fromJson(
        json['client'] as Map<String, dynamic>,
      ),
      staffNotes: json['staffNotes'] as String?,
      canStart: json['canStart'] as bool? ?? false,
      canComplete: json['canComplete'] as bool? ?? false,
    );

Map<String, dynamic> _$BookingDetailModelToJson(BookingDetailModel instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'status': instance.status,
      'channel': instance.channel,
      'scheduledStart': instance.scheduledStart,
      'scheduledEnd': instance.scheduledEnd,
      'durationMinutes': instance.durationMinutes,
      'services': instance.services,
      'client': instance.client,
      'staffNotes': instance.staffNotes,
      'canStart': instance.canStart,
      'canComplete': instance.canComplete,
    };
