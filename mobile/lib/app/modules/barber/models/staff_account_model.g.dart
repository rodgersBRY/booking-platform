// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffAccountModel _$StaffAccountModelFromJson(Map<String, dynamic> json) =>
    StaffAccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String,
    );

Map<String, dynamic> _$StaffAccountModelToJson(StaffAccountModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'role': instance.role,
      'phone': instance.phone,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'status': instance.status,
    };
