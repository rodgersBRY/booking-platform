import 'client_model.dart';
import 'staff_account_model.dart';

/// Result of a login/signup attempt. Carries either a [client] or a
/// [staff] account (never both) so `AuthRepository.login()` can report a
/// successful staff-login fallback through the same result type the
/// customer login path already returns — callers branch on [isStaff] to
/// decide which workspace to open.
class AuthResult {
  final bool success;
  final bool pendingConfirmation;
  final ClientModel? client;
  final StaffAccountModel? staff;
  final String? errorCode;
  final String? message;

  AuthResult.success(this.client)
    : success = true,
      pendingConfirmation = false,
      staff = null,
      errorCode = null,
      message = null;

  /// A staff account login (or fallback) succeeded.
  AuthResult.staffSuccess(this.staff)
    : success = true,
      pendingConfirmation = false,
      client = null,
      errorCode = null,
      message = null;

  /// Signup succeeded but the project requires email confirmation before a
  /// session is issued — no token/client yet.
  AuthResult.pendingConfirmation(this.message)
    : success = false,
      pendingConfirmation = true,
      client = null,
      staff = null,
      errorCode = null;

  AuthResult.failure(this.errorCode, this.message)
    : success = false,
      pendingConfirmation = false,
      client = null,
      staff = null;

  bool get isStaff => staff != null;
}
