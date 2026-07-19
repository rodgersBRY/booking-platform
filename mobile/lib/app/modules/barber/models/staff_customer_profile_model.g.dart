// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_customer_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffCustomerProfileModel _$StaffCustomerProfileModelFromJson(
  Map<String, dynamic> json,
) => StaffCustomerProfileModel(
  id: json['id'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  visitCount: (json['visitCount'] as num).toInt(),
  customerNotes: json['customerNotes'] as String?,
  staffNotes: json['staffNotes'] as String?,
  visits:
      (json['visits'] as List<dynamic>?)
          ?.map((e) => CustomerVisitEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$StaffCustomerProfileModelToJson(
  StaffCustomerProfileModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'visitCount': instance.visitCount,
  'customerNotes': instance.customerNotes,
  'staffNotes': instance.staffNotes,
  'visits': instance.visits,
};
