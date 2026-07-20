import 'package:json_annotation/json_annotation.dart';

import '../../booking/models/service_model.dart';
import '../../booking/models/staff_model.dart';

part 'booking_model.g.dart';

@JsonSerializable()
class BookingModel {
  final String id;
  final String status;
  final String channel;
  final String scheduledStart;
  final String scheduledEnd;
  final ServiceModel? service;
  final StaffModel? staff;
  final bool canCancel;
  final bool canReschedule;

  const BookingModel({
    required this.id,
    required this.status,
    required this.channel,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.service,
    required this.staff,
    required this.canCancel,
    required this.canReschedule,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingModelToJson(this);
}
