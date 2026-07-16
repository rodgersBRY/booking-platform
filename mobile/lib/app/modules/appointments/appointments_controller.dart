import 'package:get/get.dart';

import '../../data/models/booking_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/bookings_repository.dart';

class AppointmentsController extends GetxController {
  final BookingsRepository _repo = BookingsRepository();
  final AuthRepository _authRepo = AuthRepository();

  final loading = true.obs;
  final signedIn = false.obs;
  final error = RxnString();

  final upcoming = <BookingModel>[].obs;
  final completed = <BookingModel>[].obs;
  final cancelled = <BookingModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
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
