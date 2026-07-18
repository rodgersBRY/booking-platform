import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/models/staff_account_model.dart';
import '../../data/models/staff_day_model.dart';
import '../../data/models/staff_day_result.dart';
import '../../data/models/staff_presence.dart';
import '../../data/repositories/staff_auth_repository.dart';
import '../../data/repositories/staff_day_repository.dart';
import 'barber_shell_controller.dart';

/// Drives the barber Dashboard tab: today's day payload (presence,
/// summary, next appointment, remaining schedule) plus the signed-in
/// staff account for the header — /v1/staff/day doesn't carry
/// name/role/avatar, /v1/staff/me does.
///
/// Refreshes on pull-to-refresh, when the Dashboard tab regains focus,
/// and when the app resumes from the background (WidgetsBindingObserver)
/// — no polling timer, per the design doc's sync model.
class BarberDashboardController extends GetxController
    with WidgetsBindingObserver {
  final StaffDayRepository _dayRepo = StaffDayRepository();
  final StaffAuthRepository _authRepo = StaffAuthRepository();

  /// True only until the very first load settles. Deliberately never
  /// flips back to true on a later refresh — pull-to-refresh, tab-focus,
  /// and app-resume refreshes must never blank the page back to the
  /// skeleton.
  final loading = true.obs;

  final day = Rxn<StaffDayModel>();
  final staff = Rxn<StaffAccountModel>();

  /// Set only when there's no cached [day] to fall back on — drives the
  /// full-page error state.
  final loadError = RxnString();

  /// Set when a refresh fails but [day] already has data from an earlier
  /// successful load — drives an inline retry banner instead of blanking
  /// the page.
  final refreshError = RxnString();

  final presenceUpdating = false.obs;

  /// Set (and left set) after a failed presence change so the caller can
  /// surface it once via a snackbar, then check again for the next
  /// attempt. Not an Rx the UI binds to permanently.
  final presenceError = RxnString();

  Worker? _tabWorker;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    load();

    // Refresh whenever the barber switches back to this tab. The shell
    // keeps every tab's widget alive in an IndexedStack, so there's no
    // "page opened" lifecycle event to hook — listening to the shell's
    // own tab index is the equivalent for a GetX-driven bottom nav.
    if (Get.isRegistered<BarberShellController>()) {
      final shell = Get.find<BarberShellController>();
      _tabWorker = ever<int>(shell.currentTab, (tab) {
        if (tab == barberDashboardTabIndex) refreshDay();
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
    if (state == AppLifecycleState.resumed) refreshDay();
  }

  /// Initial load — shows the skeleton while in flight. The `finally`
  /// guarantees [loading] always clears even if something outside
  /// [_fetch]'s own error handling throws (a malformed response, say) —
  /// otherwise the skeleton's shimmer would spin forever instead of
  /// falling back to the error state.
  Future<void> load() async {
    loading.value = true;
    loadError.value = null;
    try {
      await _fetch();
    } finally {
      loading.value = false;
    }
  }

  /// Pull-to-refresh / tab-focus / app-resume refresh. Named [refreshDay]
  /// rather than `refresh` — GetxController/ListNotifier already defines
  /// a `refresh()` (forces a GetBuilder rebuild) that this would silently
  /// shadow. Never shows the skeleton and never clears already-loaded
  /// data on failure — keeps the last good [day] on screen and surfaces
  /// [refreshError] instead.
  Future<void> refreshDay() async {
    refreshError.value = null;
    await _fetch();
  }

  Future<void> _fetch() async {
    final results = await Future.wait<dynamic>([
      _dayRepo.fetchDay(),
      _authRepo.fetchMe(),
    ]);
    final dayResult = results[0] as StaffDayResult;
    final staffResult = results[1] as StaffAccountModel?;
    if (staffResult != null) staff.value = staffResult;

    if (dayResult.success) {
      day.value = dayResult.day;
      loadError.value = null;
      refreshError.value = null;
    } else if (day.value == null) {
      loadError.value = dayResult.message;
    } else {
      refreshError.value = dayResult.message;
    }
  }

  /// Optimistic status change: flips [day]'s presence immediately so the
  /// bottom sheet feels instant, then confirms against the API and
  /// reverts on failure. Controllers/widgets never see the raw
  /// DioException — [presenceError] carries a user-facing message.
  Future<void> changePresence(StaffPresence next) async {
    final current = day.value;
    if (current == null || presenceUpdating.value || current.presence == next) {
      return;
    }

    final previous = current.presence;
    day.value = current.copyWith(presence: next);
    presenceUpdating.value = true;
    presenceError.value = null;

    final result = await _dayRepo.updatePresence(next);
    presenceUpdating.value = false;

    if (result.success) {
      final latest = day.value;
      if (latest != null) {
        day.value = latest.copyWith(
          presence: result.presence ?? next,
          presenceUpdatedAt: result.presenceUpdatedAt,
        );
      }
    } else {
      final latest = day.value;
      if (latest != null) {
        day.value = latest.copyWith(presence: previous);
      }
      presenceError.value = result.message;
    }
  }
}
