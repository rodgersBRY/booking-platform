import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../models/auth_result.dart';
import '../../profile/models/client_model.dart';
import '../../barber/repositories/staff_auth_repository.dart';

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

      if (status == 401 || status == 403 || status == 404) {
        final staffResult = await StaffAuthRepository().login(
          email: email,
          password: password,
        );

        if (staffResult.success) return staffResult;
      }

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
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
        },
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
