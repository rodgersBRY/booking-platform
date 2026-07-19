import 'staff_client_model.dart';

/// Result of GET /v1/staff/clients/search?q= — same named-constructor
/// pattern as the rest of the barber module's repository results, so
/// StaffBookingRepository never lets a raw DioException reach
/// BarberCreateBookingController.
class ClientSearchResult {
  final bool success;
  final List<StaffClientModel>? clients;
  final String? errorCode;
  final String? message;

  ClientSearchResult.success(this.clients)
    : success = true,
      errorCode = null,
      message = null;

  ClientSearchResult.failure(this.errorCode, this.message)
    : success = false,
      clients = null;
}
