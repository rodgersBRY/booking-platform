import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../models/staff_customer_model.dart';
import '../models/staff_customer_profile_model.dart';
import '../models/staff_customers_result.dart';

/// The barber "My Customers" tab's data access — GET /v1/staff/clients
/// (list, optionally filtered) and GET /v1/staff/clients/[id] (profile,
/// visit timeline, notes).
///
/// Kept as its own repository rather than folded into
/// StaffBookingRepository or StaffScheduleRepository: StaffBookingRepository
/// owns the *global* client search/create used by the create-booking
/// wizard (/v1/staff/clients/search, POST /v1/staff/clients — a different
/// endpoint family with different response semantics, see
/// StaffClientModel's doc comment), and StaffScheduleRepository owns
/// per-booking detail, not per-client history. "My Customers" is its own
/// concern — distinct clients this staff member has served — so it gets
/// its own repository rather than stretching either existing one to cover
/// an endpoint family it wasn't named for. Mirrors their
/// DioException-to-result mapping so
/// BarberCustomersController/BarberCustomerProfileController never see a
/// raw Dio error.
class StaffCustomersRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  ({String? code, String? message}) _errorFrom(DioException e) {
    final data = e.response?.data;
    return (
      code: data is Map ? data['error'] as String? : null,
      message: data is Map ? data['message'] as String? : null,
    );
  }

  /// [query] omitted or empty returns every client this staff member has
  /// served — unlike StaffBookingRepository.searchClients, which floors
  /// short queries to an empty result before ever reaching the network,
  /// this endpoint treats an absent/blank `q` as "return the full list".
  Future<StaffCustomersResult> fetchMyCustomers({String? query}) async {
    final trimmed = query?.trim();
    try {
      final res = await _dio.get(
        '/v1/staff/clients',
        queryParameters:
            (trimmed == null || trimmed.isEmpty) ? null : {'q': trimmed},
      );
      final data = res.data as Map<String, dynamic>;
      final customers =
          (data['clients'] as List)
              .map(
                (e) => StaffCustomerModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
      return StaffCustomersResult.success(customers);
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return StaffCustomersResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  /// 403/404s when this staff member never served the client — surfaced
  /// as [StaffCustomerProfileResult.notServed] rather than a generic
  /// failure.
  Future<StaffCustomerProfileResult> fetchCustomerProfile(String id) async {
    try {
      final res = await _dio.get('/v1/staff/clients/$id');
      return StaffCustomerProfileResult.success(
        StaffCustomerProfileModel.fromJson(res.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final err = _errorFrom(e);
      final status = e.response?.statusCode;
      if (status == 403 || status == 404) {
        return StaffCustomerProfileResult.notServed(
          err.message ?? "You haven't served this client yet.",
        );
      }
      return StaffCustomerProfileResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
