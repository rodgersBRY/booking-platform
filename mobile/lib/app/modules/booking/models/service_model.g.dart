// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceModel _$ServiceModelFromJson(Map<String, dynamic> json) => ServiceModel(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String?,
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  price: json['price'] as num,
);

Map<String, dynamic> _$ServiceModelToJson(ServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'durationMinutes': instance.durationMinutes,
      'price': instance.price,
    };
