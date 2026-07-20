import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'models/booking_model.dart';
import '../login/repositories/auth_repository.dart';
import '../shell/shell_controller.dart';
import 'repositories/bookings_repository.dart';

class AppointmentsController extends GetxController
    with WidgetsBindingObserver {
  final BookingsRepository _repo = BookingsRepository();
  final AuthRepository _authRepo = AuthRepository();

  final loading = true.obs;
  final signedIn = false.obs;
  final error = RxnString();

  final upcoming = <BookingModel>[].obs;
  final completed = <BookingModel>[].obs;
  final cancelled = <BookingModel>[].obs;

  Worker? _tabWorker;

  @override
  void onInit() {
    super.onInit();
    load();
    WidgetsBinding.instance.addObserver(this);

    // ShellPage's IndexedStack keeps this controller alive for the whole
    // session, so without this a cancel/reschedule/new booking made
    // elsewhere wouldn't show up here until an explicit pull-to-refresh —
    // same fix as the barber Dashboard/Schedule tabs already use.
    if (Get.isRegistered<ShellController>()) {
      final shell = Get.find<ShellController>();
      _tabWorker = ever<int>(shell.currentTab, (tab) {
        if (tab == appointmentsTabIndex) load();
      });
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabWorker?.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;

    final client = await _authRepo.fetchMe();
    signedIn.value = client != null;
    if (client == null) {
      loading.value = false;
      return;
    }

    try {
      final result = await _repo.fetchMyBookings();
      upcoming.value = result['upcoming'] ?? [];
      completed.value = result['completed'] ?? [];
      cancelled.value = result['cancelled'] ?? [];
    } catch (_) {
      error.value = "Couldn't load your appointments. Please try again.";
    } finally {
      loading.value = false;
    }
  }
}
