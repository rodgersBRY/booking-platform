import 'package:get/get.dart';

import 'models/staff_appointment_model.dart';
import 'repositories/staff_schedule_repository.dart';
import 'barber_shell_controller.dart';

/// The three ranges the Schedule tab's segmented control offers, in
/// display order — also the exact `range` query values
/// GET /v1/staff/schedule expects.
const scheduleRanges = ['today', 'tomorrow', 'week'];

/// Drives the barber Schedule tab. Unlike the Dashboard's single "today"
/// payload, each range is its own server-side query, so switching tabs
/// re-fetches rather than filtering a locally-cached list.
class BarberScheduleController extends GetxController {
  final StaffScheduleRepository _repo = StaffScheduleRepository();

  final range = scheduleRanges.first.obs;

  /// True only while the active range's data is in flight — flips back to
  /// true on every range switch (each range is effectively a fresh
  /// screen), but pull-to-refresh on an already-loaded range uses
  /// [refreshSchedule] instead so it doesn't blank the list.
  final loading = true.obs;

  final schedule = <StaffAppointmentModel>[].obs;

  /// Set only when there's no data at all to fall back on for the active
  /// range — drives the full-page error state.
  final loadError = RxnString();

  /// Set when a pull-to-refresh fails but [schedule] already has data —
  /// drives an inline retry banner instead of blanking the list.
  final refreshError = RxnString();

  Worker? _tabWorker;

  @override
  void onInit() {
    super.onInit();
    load();

    // Refresh the active range whenever the barber switches back to this
    // tab — same rationale as BarberDashboardController's tab-focus
    // refresh (the shell keeps every tab alive in an IndexedStack, so
    // there's no page-opened lifecycle hook to use instead).
    if (Get.isRegistered<BarberShellController>()) {
      final shell = Get.find<BarberShellController>();
      _tabWorker = ever<int>(shell.currentTab, (tab) {
        if (tab == barberScheduleTabIndex) refreshSchedule();
      });
    }
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    super.onClose();
  }

  Future<void> changeRange(String next) async {
    if (range.value == next || loading.value) return;
    range.value = next;
    await load();
  }

  /// Initial (or range-switch) load — shows the skeleton while in flight.
  /// Clears any previous range's items first: they belong to a different
  /// query and would otherwise read as (wrong) results for the new range
  /// if this fetch fails and falls back to "show what we have".
  Future<void> load() async {
    loading.value = true;
    loadError.value = null;
    schedule.clear();
    try {
      await _fetch();
    } finally {
      loading.value = false;
    }
  }

  /// Pull-to-refresh / tab-focus refresh for the active range. Never
  /// shows the skeleton and never clears already-loaded data on failure.
  Future<void> refreshSchedule() async {
    refreshError.value = null;
    await _fetch();
  }

  Future<void> _fetch() async {
    final result = await _repo.fetchSchedule(range.value);
    if (result.success) {
      schedule.assignAll(result.schedule ?? []);
      loadError.value = null;
      refreshError.value = null;
    } else if (schedule.isEmpty) {
      loadError.value = result.message;
    } else {
      refreshError.value = result.message;
    }
  }
}
