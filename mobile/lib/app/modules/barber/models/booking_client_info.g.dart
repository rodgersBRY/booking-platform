// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_client_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingClientInfo _$BookingClientInfoFromJson(Map<String, dynamic> json) =>
    BookingClientInfo(
      name: json['name'] as String,
      phone: json['phone'] as String,
      totalVisits: (json['totalVisits'] as num).toInt(),
      customerNotes: json['customerNotes'] as String?,
    );

Map<String, dynamic> _$BookingClientInfoToJson(BookingClientInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'totalVisits': instance.totalVisits,
      'customerNotes': instance.customerNotes,
    };
