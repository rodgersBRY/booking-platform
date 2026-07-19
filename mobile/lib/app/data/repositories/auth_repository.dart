import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../models/auth_result.dart';
import '../models/client_model.dart';
import 'staff_auth_repository.dart';

/// Client account auth — /api/account/* on the same Next.js backend the
/// booking flow uses.
///
/// One login screen serves both customers and staff. `login()` tries the
/// client endpoint first; on an auth failure (401/403) it retries against
/// staff login before giving up. This lives here rather than in the login
/// controller so every caller of `AuthRepository.login()` gets the
/// auto-detect behaviour for free, and so the controller stays a thin
/// dispatcher that only reacts to `AuthResult.isStaff` instead of knowing
/// two repositories exist.
class AuthRepository {
  Dio get _dio => Get.find<ApiService>().dio;
  StorageService get _storage => Get.find<StorageService>();

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/v1/account/login',
        data: {'email': email, 'password': password},
      );
      final token = res.data['token'] as String;
      await _storage.writeToken(token);
      await _storage.writeAccountType('client');
      final client = ClientModel.fromJson(
        res.data['client'] as Map<String, dynamic>,
      );
      return AuthResult.success(client);
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      // Only fall back on an auth rejection, not on network/server
      // errors — a timeout shouldn't turn into two failing requests, and
      // this keeps the client error message intact for non-auth failures.
      if (status == 401 || status == 403) {
        final staffResult = await StaffAuthRepository().login(
          email: email,
          password: password,
        );
        if (staffResult.success) return staffResult;
      }

      // Both paths rejected (or only the client path was tried): surface
      // the original client failure. Returning the client's own message
      // rather than the staff one avoids revealing whether an email
      // belongs to a staff account.
      final data = e.response?.data;
      final code = data is Map ? data['error'] as String? : null;
      final message = data is Map ? data['message'] as String? : null;
      return AuthResult.failure(
        code,
        message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<AuthResult> signup({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/v1/account/signup',
        data: {'name': name, 'phone': phone, 'email': email, 'password': password},
      );
      if (res.data['pendingConfirmation'] == true) {
        return AuthResult.pendingConfirmation(res.data['message'] as String?);
      }
      final token = res.data['token'] as String;
      await _storage.writeToken(token);
      final client = ClientModel.fromJson(
        res.data['client'] as Map<String, dynamic>,
      );
      return AuthResult.success(client);
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map ? data['error'] as String? : null;
      final message = data is Map ? data['message'] as String? : null;
      return AuthResult.failure(
        code,
        message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  /// Resolves the current session's client profile, or null if there's no
  /// valid token (never signed in, or it expired/was revoked).
  Future<ClientModel?> fetchMe() async {
    final token = await _storage.readToken();
    if (token == null) return null;
    try {
      final res = await _dio.get('/v1/account/me');
      return ClientModel.fromJson(res.data['client'] as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();
  }
}
