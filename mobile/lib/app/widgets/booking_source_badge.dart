import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Maps a booking's `channel` to a human label — "Booked via Mobile App"
/// on the barber Dashboard/Schedule/appointment-detail screens. Slice 3
/// adds `mobile_app`, `reception`, and `barber` on top of today's
/// `online`/`walkin`/`whatsapp`/`phone` values; an unrecognised value
/// degrades to a title-cased label instead of crashing, so a new channel
/// added on the backend never breaks this badge before it's updated.
class BookingSourceBadge extends StatelessWidget {
  final String channel;

  const BookingSourceBadge({super.key, required this.channel});

  static const _labels = {
    'online': 'Mobile App',
    'walkin': 'Walk-In',
    'whatsapp': 'WhatsApp',
    'phone': 'Phone',
    'mobile_app': 'Mobile App',
    'reception': 'Reception',
    'barber': 'Barber',
  };

  String get _label {
    final known = _labels[channel];
    if (known != null) return known;
    return channel
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.brass.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.brass,
        ),
      ),
    );
  }
}
