// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_client_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffClientModel _$StaffClientModelFromJson(Map<String, dynamic> json) =>
    StaffClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      preferredStaffId: json['preferredStaffId'] as String?,
      preferredStaffName: json['preferredStaffName'] as String?,
      totalVisits: (json['totalVisits'] as num?)?.toInt() ?? 0,
      lastVisitAt: json['lastVisitAt'] as String?,
      isRegular: json['isRegular'] as bool? ?? false,
    );

Map<String, dynamic> _$StaffClientModelToJson(StaffClientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'preferredStaffId': instance.preferredStaffId,
      'preferredStaffName': instance.preferredStaffName,
      'totalVisits': instance.totalVisits,
      'lastVisitAt': instance.lastVisitAt,
      'isRegular': instance.isRegular,
    };
