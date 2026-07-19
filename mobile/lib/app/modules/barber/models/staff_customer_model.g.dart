// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffCustomerModel _$StaffCustomerModelFromJson(Map<String, dynamic> json) =>
    StaffCustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      visitCount: (json['visitCount'] as num).toInt(),
      lastVisitAt: json['lastVisitAt'] as String,
    );

Map<String, dynamic> _$StaffCustomerModelToJson(StaffCustomerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'visitCount': instance.visitCount,
      'lastVisitAt': instance.lastVisitAt,
    };
