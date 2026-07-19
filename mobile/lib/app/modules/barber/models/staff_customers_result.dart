import 'staff_customer_model.dart';
import 'staff_customer_profile_model.dart';

/// Result of GET /v1/staff/clients?q= — same named-constructor pattern as
/// the rest of the barber module's repository results, so
/// StaffCustomersRepository never lets a raw DioException reach
/// BarberCustomersController.
class StaffCustomersResult {
  final bool success;
  final List<StaffCustomerModel>? customers;
  final String? errorCode;
  final String? message;

  StaffCustomersResult.success(this.customers)
    : success = true,
      errorCode = null,
      message = null;

  StaffCustomersResult.failure(this.errorCode, this.message)
    : success = false,
      customers = null;
}

/// Result of GET /v1/staff/clients/[id]. [notServed] is its own named
/// constructor (not folded into [failure]) so
/// BarberCustomerProfileController can tell the 403/404 "this staff
/// member never served this client" case apart from a generic failure and
/// show a specific, non-retryable message instead of the usual
/// retry-oriented error state — mirrors BookingStartResult.staffBusy in
/// the appointment-detail module.
class StaffCustomerProfileResult {
  final bool success;
  final StaffCustomerProfileModel? profile;
  final bool notServed;
  final String? errorCode;
  final String? message;

  StaffCustomerProfileResult.success(this.profile)
    : success = true,
      notServed = false,
      errorCode = null,
      message = null;

  StaffCustomerProfileResult.notServed(this.message)
    : success = false,
      profile = null,
      notServed = true,
      errorCode = 'not_served';

  StaffCustomerProfileResult.failure(this.errorCode, this.message)
    : success = false,
      profile = null,
      notServed = false;
}
