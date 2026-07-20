import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// Wraps secure on-device storage for the auth session token, which
/// workspace that session belongs to, and the user's appearance
/// preference. Registered as a permanent GetxService in main.dart.
class StorageService extends GetxService {
  static const _tokenKey = 'auth_token';
  static const _accountTypeKey = 'account_type';
  static const _themeModeKey = 'theme_mode';

  final _storage = const FlutterSecureStorage();

  Future<StorageService> init() async => this;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Which workspace the stored token belongs to: `"client"` or `"staff"`.
  /// Read at startup to decide whether to open the customer shell or the
  /// barber shell.
  Future<String?> readAccountType() => _storage.read(key: _accountTypeKey);

  Future<void> writeAccountType(String accountType) =>
      _storage.write(key: _accountTypeKey, value: accountType);

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _accountTypeKey);
  }

  /// Defaults to ThemeMode.system when nothing has been saved yet.
  Future<ThemeMode> readThemeMode() async {
    final raw = await _storage.read(key: _themeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> writeThemeMode(ThemeMode mode) =>
      _storage.write(key: _themeModeKey, value: mode.name);
}
