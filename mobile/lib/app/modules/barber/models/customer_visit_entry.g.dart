// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_visit_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerVisitEntry _$CustomerVisitEntryFromJson(Map<String, dynamic> json) =>
    CustomerVisitEntry(
      date: json['date'] as String,
      services:
          (json['services'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$CustomerVisitEntryToJson(CustomerVisitEntry instance) =>
    <String, dynamic>{'date': instance.date, 'services': instance.services};
