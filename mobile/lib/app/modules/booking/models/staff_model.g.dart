// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffModel _$StaffModelFromJson(Map<String, dynamic> json) => StaffModel(
  id: json['id'] as String,
  name: json['name'] as String,
  role: json['role'] as String,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$StaffModelToJson(StaffModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'role': instance.role,
      'avatarUrl': instance.avatarUrl,
    };
