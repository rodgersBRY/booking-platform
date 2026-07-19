import 'package:flutter/material.dart';

/// Ported from the web dashboard's CSS custom properties
/// (web/src/app/globals.css) so the mobile app and web stay visually
/// consistent under one brand.
abstract class AppColors {
  static const navy = Color(0xFF1A2540);
  static const navyLight = Color(0xFF243050);

  static const brass = Color(0xFFB8893A);
  static const brassLight = Color(0xFFD4A84B);

  static const canvas = Color(0xFFF4F5F7);
  static const card = Color(0xFFFFFFFF);

  static const free = Color(0xFF16A34A);
  static const freeBg = Color(0xFFDCFCE7);
  static const waiting = Color(0xFFD97706);
  static const waitingBg = Color(0xFFFEF3C7);
  static const inChair = Color(0xFF2563EB);
  static const inChairBg = Color(0xFFDBEAFE);
  static const late = Color(0xFFDC2626);
  static const lateBg = Color(0xFFFEE2E2);

  // Slice 3: "in progress" (booking status in_chair) gets its own purple —
  // distinct from inChair's blue, which now means "confirmed" on the
  // barber Schedule/appointment-detail status legend
  // (docs/superpowers/specs/2026-07-18-barber-workspace-design.md).
  static const inProgress = Color(0xFF9333EA);
  static const inProgressBg = Color(0xFFF3E8FF);

  // Dark-mode surfaces — brightness-dependent, not a simple opacity shift
  // of the light tokens above.
  static const canvasDark = Color(0xFF10131F);
  static const cardDark = Color(0xFF1C2136);
  static const borderDark = Color(0xFF323A57);
}
