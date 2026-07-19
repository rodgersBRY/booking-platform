import 'staff_client_model.dart';

/// Result of POST /v1/staff/clients. [phoneTaken] gets its own named
/// constructor (not folded into [failure]) so the quick-registration form
/// can tell the 409 "a client with this phone number already exists"
/// conflict apart from any other failure and keep the form open with a
/// field-level error instead of a dead-end toast — mirrors
/// BookingStartResult.staffBusy in this same module.
class NewClientResult {
  final bool success;
  final StaffClientModel? client;
  final bool phoneTaken;
  final String? errorCode;
  final String? message;

  NewClientResult.success(this.client)
    : success = true,
      phoneTaken = false,
      errorCode = null,
      message = null;

  NewClientResult.phoneTaken(this.message)
    : success = false,
      client = null,
      phoneTaken = true,
      errorCode = 'phone_taken';

  NewClientResult.failure(this.errorCode, this.message)
    : success = false,
      client = null,
      phoneTaken = false;
}
