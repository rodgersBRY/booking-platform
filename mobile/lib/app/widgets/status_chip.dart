import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Colored pill for a booking status, mapped onto the existing status
/// palette shared with the web dashboard.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  static const _labels = {
    'booked': 'Booked',
    'arrived': 'Arrived',
    'in_chair': 'In progress',
    'completed': 'Completed',
    'late': 'Running late',
    'no_show': 'Missed',
    'cancelled': 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      'completed' => (AppColors.free, AppColors.freeBg),
      'cancelled' || 'no_show' => (AppColors.late, AppColors.lateBg),
      'late' => (AppColors.waiting, AppColors.waitingBg),
      'arrived' || 'in_chair' => (AppColors.inChair, AppColors.inChairBg),
      _ => (AppColors.brass, Color(0xFFF8EFDD)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
