import 'client_model.dart';

class AuthResult {
  final bool success;
  final bool pendingConfirmation;
  final ClientModel? client;
  final String? errorCode;
  final String? message;

  AuthResult.success(this.client)
    : success = true,
      pendingConfirmation = false,
      errorCode = null,
      message = null;

  /// Signup succeeded but the project requires email confirmation before a
  /// session is issued — no token/client yet.
  AuthResult.pendingConfirmation(this.message)
    : success = false,
      pendingConfirmation = true,
      client = null,
      errorCode = null;

  AuthResult.failure(this.errorCode, this.message)
    : success = false,
      pendingConfirmation = false,
      client = null;
}
