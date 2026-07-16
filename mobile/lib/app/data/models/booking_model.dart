import 'service_model.dart';
import 'staff_model.dart';

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

  BookingModel({
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

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      status: json['status'] as String,
      channel: json['channel'] as String,
      scheduledStart: json['scheduledStart'] as String,
      scheduledEnd: json['scheduledEnd'] as String,
      service: json['service'] != null
          ? ServiceModel.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      staff: json['staff'] != null
          ? StaffModel.fromJson(json['staff'] as Map<String, dynamic>)
          : null,
      canCancel: json['canCancel'] as bool,
      canReschedule: json['canReschedule'] as bool,
    );
  }
}
