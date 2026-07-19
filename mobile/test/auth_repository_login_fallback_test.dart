import 'package:barberia_cuts/app/modules/login/repositories/auth_repository.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_services.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('falls back to staff login when the client login is rejected', () async {
    final adapter = ScriptedAdapter({
      '/v1/account/login': (
        status: 401,
        body: {
          'error': 'invalid_credentials',
          'message': 'Wrong email or password.',
        },
      ),
      '/v1/staff/login': (
        status: 200,
        body: {
          'token': 'staff-token',
          'staff': {
            'id': 's1',
            'name': 'James Mwangi',
            'role': 'barber',
            'phone': '0700000000',
            'email': 'james@shop.com',
            'avatarUrl': null,
            'status': 'active',
          },
        },
      ),
    });
    final storage = FakeStorageService();
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(storage);

    final result = await AuthRepository().login(
      email: 'james@shop.com',
      password: 'secret',
    );

    expect(adapter.requestedPaths, ['/v1/account/login', '/v1/staff/login']);
    expect(result.success, isTrue);
    expect(result.isStaff, isTrue);
    expect(result.staff?.name, 'James Mwangi');
    expect(result.client, isNull);
    expect(storage.token, 'staff-token');
    expect(storage.accountType, 'staff');
  });

  test('does not fall back when the client login succeeds', () async {
    final adapter = ScriptedAdapter({
      '/v1/account/login': (
        status: 200,
        body: {
          'token': 'client-token',
          'client': {
            'id': 'c1',
            'name': 'Brian',
            'phone': '0711111111',
            'email': 'brian@example.com',
            'loyaltyPoints': 10,
            'totalVisits': 3,
          },
        },
      ),
    });
    final storage = FakeStorageService();
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(storage);

    final result = await AuthRepository().login(
      email: 'brian@example.com',
      password: 'secret',
    );

    expect(adapter.requestedPaths, ['/v1/account/login']);
    expect(result.success, isTrue);
    expect(result.isStaff, isFalse);
    expect(result.client?.name, 'Brian');
    expect(storage.accountType, 'client');
  });

  test(
    'surfaces the original client error when both logins are rejected',
    () async {
      final adapter = ScriptedAdapter({
        '/v1/account/login': (
          status: 401,
          body: {
            'error': 'invalid_credentials',
            'message': 'Wrong email or password.',
          },
        ),
        '/v1/staff/login': (
          status: 401,
          body: {
            'error': 'invalid_credentials',
            'message': 'Wrong email or password.',
          },
        ),
      });
      Get.put<ApiService>(FakeApiService(adapter));
      Get.put<StorageService>(FakeStorageService());

      final result = await AuthRepository().login(
        email: 'nobody@example.com',
        password: 'wrong',
      );

      expect(adapter.requestedPaths, ['/v1/account/login', '/v1/staff/login']);
      expect(result.success, isFalse);
      expect(result.isStaff, isFalse);
      expect(result.message, 'Wrong email or password.');
    },
  );

  test('does not attempt a staff fallback on a non-auth failure', () async {
    final adapter = ScriptedAdapter({
      '/v1/account/login': (
        status: 500,
        body: {'error': 'server_error', 'message': 'Something broke.'},
      ),
    });
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(FakeStorageService());

    final result = await AuthRepository().login(
      email: 'brian@example.com',
      password: 'secret',
    );

    expect(adapter.requestedPaths, ['/v1/account/login']);
    expect(result.success, isFalse);
    expect(result.message, 'Something broke.');
  });
}
