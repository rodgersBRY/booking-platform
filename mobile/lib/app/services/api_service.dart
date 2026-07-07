import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'storage_service.dart';

/// Thin Dio wrapper pointed at the existing Next.js API (shared with web).
/// Registered as a permanent GetxService in main.dart.
class ApiService extends GetxService {
  late final Dio dio;

  Future<ApiService> init() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await Get.find<StorageService>().readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          handler.next(options);
        },
      ),
    );

    return this;
  }
}
