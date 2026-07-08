import 'client_model.dart';

class AuthResult {
  final bool success;
  final ClientModel? client;
  final String? errorCode;
  final String? message;

  AuthResult.success(this.client)
    : success = true,
      errorCode = null,
      message = null;

  AuthResult.failure(this.errorCode, this.message)
    : success = false,
      client = null;
}
