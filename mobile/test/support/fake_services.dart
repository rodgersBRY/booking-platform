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
///
/// Lookup tries, most specific first: `"$METHOD $path?$sortedQuery"`,
/// `"$METHOD $path"`, `"$path?$sortedQuery"`, then plain `path` — so
/// existing scripts keyed by bare path (the common case: one method, no
/// query params, per path) keep working unchanged, while a test that
/// needs to disambiguate GET vs PATCH on the same path (e.g.
/// /v1/staff/bookings/[id]) or different query params on the same path
/// (e.g. /v1/staff/schedule?range=...) can opt in by keying its script
/// map more specifically.
class ScriptedAdapter implements HttpClientAdapter {
  final List<String> requestedPaths = [];
  final Map<String, ScriptedResponse> _script;

  ScriptedAdapter(this._script);

  String _withQuery(RequestOptions options) {
    if (options.queryParameters.isEmpty) return options.path;
    final sorted =
        options.queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final query = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return '${options.path}?$query';
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
    final method = options.method.toUpperCase();
    final withQuery = _withQuery(options);
    final entry =
        _script['$method $withQuery'] ??
        _script['$method ${options.path}'] ??
        _script[withQuery] ??
        _script[options.path];
    if (entry == null) {
      throw StateError('No scripted response for $method $withQuery');
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

/// A minimal, fully-populated /v1/staff/day response body — reused across
/// barber Dashboard widget tests so each test only overrides the fields
/// it cares about.
Map<String, dynamic> sampleStaffDayJson({
  String presence = 'available',
  Map<String, dynamic>? nextAppointment,
  List<Map<String, dynamic>>? schedule,
  Map<String, dynamic>? summary,
}) {
  return {
    'staffId': 'staff-1',
    'presence': presence,
    'presenceUpdatedAt': '2026-07-18T08:00:00.000Z',
    'workingHours': {'start': '09:00', 'end': '19:00'},
    'summary': summary ?? {'total': 8, 'completed': 3, 'remaining': 5},
    'nextAppointment': nextAppointment,
    'schedule': schedule ?? (nextAppointment != null ? [nextAppointment] : []),
  };
}

/// One GET /v1/staff/schedule?range=... entry — same shape as
/// /v1/staff/day's schedule rows (StaffAppointmentModel), reused across
/// barber Schedule widget tests.
Map<String, dynamic> sampleScheduleEntryJson({
  String bookingId = 'b1',
  String clientName = 'Brian Mwangi',
  List<String> services = const ['Haircut', 'Beard Trim'],
  String scheduledStart = '2026-07-18T10:30:00.000Z',
  String scheduledEnd = '2026-07-18T11:15:00.000Z',
  int durationMinutes = 45,
  String status = 'booked',
  String channel = 'online',
}) {
  return {
    'bookingId': bookingId,
    'clientName': clientName,
    'services': services,
    'scheduledStart': scheduledStart,
    'scheduledEnd': scheduledEnd,
    'durationMinutes': durationMinutes,
    'status': status,
    'channel': channel,
  };
}

/// A GET /v1/staff/schedule?range=... response body.
Map<String, dynamic> sampleScheduleJson({
  String range = 'today',
  List<Map<String, dynamic>>? schedule,
}) {
  return {'range': range, 'schedule': schedule ?? []};
}

/// A GET /v1/staff/bookings/[id] response body — also matches the
/// `booking` shape POST /v1/staff/bookings/[id]/start returns.
Map<String, dynamic> sampleBookingDetailJson({
  String bookingId = 'b1',
  String status = 'arrived',
  String channel = 'online',
  String scheduledStart = '2026-07-18T10:30:00.000Z',
  String scheduledEnd = '2026-07-18T11:15:00.000Z',
  int durationMinutes = 45,
  List<String> services = const ['Haircut', 'Beard Trim'],
  String clientName = 'Brian Mwangi',
  String clientPhone = '0700000000',
  int totalVisits = 14,
  String? customerNotes = 'Prefers Skin Fade.',
  String? staffNotes = 'Usually books every three weeks.',
  bool canStart = true,
  bool canComplete = false,
}) {
  return {
    'bookingId': bookingId,
    'status': status,
    'channel': channel,
    'scheduledStart': scheduledStart,
    'scheduledEnd': scheduledEnd,
    'durationMinutes': durationMinutes,
    'services': services,
    'client': {
      'name': clientName,
      'phone': clientPhone,
      'totalVisits': totalVisits,
      'customerNotes': customerNotes,
    },
    'staffNotes': staffNotes,
    'canStart': canStart,
    'canComplete': canComplete,
  };
}

/// A canned /v1/staff/me response body for the Dashboard header. Wrapped
/// under a `staff` key, matching what StaffAuthRepository.fetchMe()
/// actually reads (`res.data['staff']`) — the same shape
/// auth_repository_login_fallback_test.dart uses for `/v1/staff/login`.
Map<String, dynamic> sampleStaffAccountJson() {
  return {
    'staff': {
      'id': 'staff-1',
      'name': 'James Mwangi',
      'role': 'barber',
      'phone': '0700000000',
      'email': 'james@shop.com',
      'avatarUrl': null,
      'status': 'active',
    },
  };
}

/// One GET /v1/staff/clients/search entry / POST /v1/staff/clients
/// `client` payload — same shape StaffClientModel.fromJson reads, used
/// across the barber create-booking wizard's tests.
Map<String, dynamic> sampleStaffClientJson({
  String id = 'client-1',
  String name = 'Brian Mwangi',
  String phone = '0700000001',
  String? preferredStaffId,
  String? preferredStaffName,
  int totalVisits = 3,
  String? lastVisitAt,
  bool isRegular = false,
}) {
  return {
    'id': id,
    'name': name,
    'phone': phone,
    'preferredStaffId': preferredStaffId,
    'preferredStaffName': preferredStaffName,
    'totalVisits': totalVisits,
    'lastVisitAt': lastVisitAt,
    'isRegular': isRegular,
  };
}

/// One GET /v1/staff/services entry — same shape the customer booking
/// wizard's ServiceModel.fromJson reads.
Map<String, dynamic> sampleStaffServiceJson({
  String id = 'svc-1',
  String name = 'Haircut',
  String? category = 'haircuts',
  int durationMinutes = 45,
  num price = 800,
}) {
  return {
    'id': id,
    'name': name,
    'category': category,
    'durationMinutes': durationMinutes,
    'price': price,
  };
}

/// One GET /v1/staff/availability slot entry — same shape the customer
/// booking wizard's SlotModel.fromJson reads.
Map<String, dynamic> sampleStaffSlotJson({
  required String start,
  required String end,
  required String label,
  String staffId = 'staff-1',
}) {
  return {'start': start, 'end': end, 'label': label, 'staffId': staffId};
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
