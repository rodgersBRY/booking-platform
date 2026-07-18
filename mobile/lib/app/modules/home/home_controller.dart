import 'package:get/get.dart';

import '../../data/models/booking_model.dart';
import '../../data/models/client_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/bookings_repository.dart';
import '../booking/booking_binding.dart';
import '../booking/booking_controller.dart';

class HomeController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final BookingRepository _bookingRepo = BookingRepository();
  final BookingsRepository _bookingsRepo = BookingsRepository();

  /// Null while loading or when browsing as a guest.
  final client = Rxn<ClientModel>();

  /// The client's next upcoming booking, if any — null for guests too.
  final upcomingBooking = Rxn<BookingModel>();

  final services = <ServiceModel>[].obs;
  final staff = <StaffModel>[].obs;
  final loading = true.obs;
  final error = RxnString();

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Unique categories in first-seen order (uncategorized services are
  /// reachable through the full wizard, not the home shortcuts).
  List<String> get categories {
    final seen = <String>[];
    for (final s in services) {
      final key = s.category;
      if (key != null && key.trim().isNotEmpty && !seen.contains(key)) {
        seen.add(key);
      }
    }
    return seen;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _bookingRepo.fetchServices(),
        _bookingRepo.fetchStaff(),
      ]);
      services.value = results[0] as List<ServiceModel>;
      staff.value = results[1] as List<StaffModel>;
    } catch (_) {
      error.value = "Couldn't load right now. Pull down to try again.";
    } finally {
      loading.value = false;
    }
    // Guest-safe: null just means nobody is signed in.
    client.value = await _authRepo.fetchMe();

    if (client.value != null) {
      try {
        final bookings = await _bookingsRepo.fetchMyBookings();
        upcomingBooking.value = bookings['upcoming']?.firstOrNull;
      } catch (_) {
        // Non-critical for this screen — Appointments tab is the source
        // of truth and has its own error handling.
      }
    } else {
      upcomingBooking.value = null;
    }
  }

  /// Ensures the booking wizard's controller exists (its route binding
  /// hasn't necessarily run yet when entering from a home shortcut).
  BookingController _booking() {
    if (!Get.isRegistered<BookingController>()) {
      BookingBinding().dependencies();
    }
    return Get.find<BookingController>();
  }

  /// Home category shortcut → straight into that category's service list.
  void openCategory(String category) => _booking().selectCategory(category);

  /// Home service shortcut → straight to the staff step for that service.
  void openService(ServiceModel service) => _booking().selectService(service);
}
