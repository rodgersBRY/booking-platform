import 'dart:convert';
import 'dart:typed_data';

import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:dio/dio.dart';

/// A canned status + JSON body for one request path.
typedef ScriptedResponse = ({int status, Map<String, dynamic> body});

/// In-memory [HttpClientAdapter] for repository tests: maps request paths
/// to canned JSON responses instead of touching the network, and records
/// every path requested so a test can assert which endpoints were (or
/// weren't) called and in what order.
class ScriptedAdapter implements HttpClientAdapter {
  final List<String> requestedPaths = [];
  final Map<String, ScriptedResponse> _script;

  ScriptedAdapter(this._script);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
    final entry = _script[options.path];
    if (entry == null) {
      throw StateError('No scripted response for ${options.path}');
    }
    return ResponseBody.fromString(
      jsonEncode(entry.body),
      entry.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// An adapter for tests that shouldn't hit the network at all — fails
/// loudly instead of silently returning something a test might mistake
/// for a real response.
class NoRequestsExpectedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw StateError('Unexpected request to ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

/// ApiService with its Dio wired to a fake adapter instead of a real HTTP
/// client, so repository tests never touch the network.
class FakeApiService extends ApiService {
  FakeApiService(HttpClientAdapter adapter) {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    dio.httpClientAdapter = adapter;
  }
}

/// In-memory StorageService double — avoids FlutterSecureStorage's
/// platform channel, which isn't available under flutter_test.
class FakeStorageService extends StorageService {
  String? token;
  String? accountType;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<String?> readAccountType() async => accountType;

  @override
  Future<void> writeAccountType(String value) async => accountType = value;

  @override
  Future<void> clearToken() async {
    token = null;
    accountType = null;
  }
}
