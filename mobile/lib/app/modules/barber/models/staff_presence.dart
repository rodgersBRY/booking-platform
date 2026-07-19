import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// The barber's live on/off status — distinct from a booking's status
/// (see status_chip.dart). Backed by `staff.presence` /
/// `staff.presence_updated_at` (Slice 2 migration), defaulting to
/// `off_duty`. Changed via PATCH /v1/staff/presence.
enum StaffPresence {
  available,
  busy,
  onBreak,
  offDuty;

  static StaffPresence fromJson(String value) {
    return switch (value) {
      'available' => StaffPresence.available,
      'busy' => StaffPresence.busy,
      'on_break' => StaffPresence.onBreak,
      'off_duty' => StaffPresence.offDuty,
      _ => StaffPresence.offDuty,
    };
  }

  String get value => switch (this) {
    StaffPresence.available => 'available',
    StaffPresence.busy => 'busy',
    StaffPresence.onBreak => 'on_break',
    StaffPresence.offDuty => 'off_duty',
  };

  String get label => switch (this) {
    StaffPresence.available => 'Available',
    StaffPresence.busy => 'Busy',
    StaffPresence.onBreak => 'On Break',
    StaffPresence.offDuty => 'Off Duty',
  };

  /// Themed status-dot color. BARBER-APP.md illustrates the four states
  /// with emoji (🟢🟡🔴⚫) — those are illustrative only; the UI renders a
  /// coloured dot from the app's existing status palette instead of
  /// hardcoding emoji as icons. Available/busy/on-break reuse the same
  /// green/red/amber tokens status_chip.dart uses for booking status,
  /// since they carry the same "go / stop / pause" meaning here. Off-duty
  /// has no existing token (nothing in the booking-status palette means
  /// "not working"), so it uses a plain neutral grey.
  Color get color => switch (this) {
    StaffPresence.available => AppColors.free,
    StaffPresence.busy => AppColors.late,
    StaffPresence.onBreak => AppColors.waiting,
    StaffPresence.offDuty => Colors.grey,
  };

  Color get backgroundColor => switch (this) {
    StaffPresence.available => AppColors.freeBg,
    StaffPresence.busy => AppColors.lateBg,
    StaffPresence.onBreak => AppColors.waitingBg,
    StaffPresence.offDuty => const Color(0xFFE5E7EB),
  };
}
