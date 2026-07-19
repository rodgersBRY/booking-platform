import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modules/appointments/models/booking_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'status_chip.dart';

class AppointmentCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const AppointmentCard({super.key, required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.parse(booking.scheduledStart).toLocal();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _Avatar(url: booking.staff?.avatarUrl, name: booking.staff?.name ?? '?'),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.service?.name ?? 'Appointment',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  if (booking.staff != null)
                    Text(booking.staff!.name, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('EEE, d MMM').format(start)} · ${DateFormat('h:mm a').format(start)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusChip(status: booking.status),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;

  const _Avatar({required this.url, required this.name});

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
    final imageUrl = url;
    if (imageUrl == null) return fallback;
    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, image) =>
          CircleAvatar(radius: radius, backgroundImage: image),
      placeholder: (context, _) => fallback,
      errorWidget: (context, _, __) => fallback,
    );
  }
}
