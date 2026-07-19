import '../../booking/models/service_model.dart';

/// Result of GET /v1/staff/services — reuses the customer booking flow's
/// ServiceModel directly since the backend contract describes the same
/// response shape, already filtered to this barber's own role.
class StaffServicesResult {
  final bool success;
  final List<ServiceModel>? services;
  final String? errorCode;
  final String? message;

  StaffServicesResult.success(this.services)
    : success = true,
      errorCode = null,
      message = null;

  StaffServicesResult.failure(this.errorCode, this.message)
    : success = false,
      services = null;
}
