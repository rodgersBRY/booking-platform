import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../models/auth_result.dart';
import '../models/client_model.dart';

/// Client account auth — /api/account/* on the same Next.js backend the
/// booking flow uses. Distinct from staff auth (staff never sign in from
/// this app).
class AuthRepository {
  Dio get _dio => Get.find<ApiService>().dio;
  StorageService get _storage => Get.find<StorageService>();

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/account/login',
        data: {'email': email, 'password': password},
      );
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
      final res = await _dio.get('/account/me');
      return ClientModel.fromJson(res.data['client'] as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();
  }
}
