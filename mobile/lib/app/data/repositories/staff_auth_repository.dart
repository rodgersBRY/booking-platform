import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../models/auth_result.dart';
import '../models/staff_account_model.dart';

/// Staff account auth — /api/v1/staff/* on the same Next.js backend the
/// client booking flow uses. Mirrors AuthRepository's structure and its
/// DioException-to-result mapping so controllers never see raw Dio
/// errors, and stamps accountType = "staff" alongside the token so app
/// startup knows to open the barber shell instead of the customer shell.
class StaffAuthRepository {
  Dio get _dio => Get.find<ApiService>().dio;
  StorageService get _storage => Get.find<StorageService>();

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/v1/staff/login',
        data: {'email': email, 'password': password},
      );
      final token = res.data['token'] as String;
      await _storage.writeToken(token);
      await _storage.writeAccountType('staff');
      final staff = StaffAccountModel.fromJson(
        res.data['staff'] as Map<String, dynamic>,
      );
      return AuthResult.staffSuccess(staff);
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

  /// Resolves the current session's staff profile, or null if there's no
  /// valid token (never signed in, or it expired/was revoked).
  Future<StaffAccountModel?> fetchMe() async {
    final token = await _storage.readToken();
    if (token == null) return null;
    try {
      final res = await _dio.get('/v1/staff/me');
      return StaffAccountModel.fromJson(
        res.data['staff'] as Map<String, dynamic>,
      );
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();
  }
}
