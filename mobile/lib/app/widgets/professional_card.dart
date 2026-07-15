import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// Staff row card: cached avatar photo (or initials / group icon for the
/// "any professional" option), name, and role subtitle.
class ProfessionalCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final bool selected;
  final bool isAny;
  final VoidCallback onTap;

  const ProfessionalCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.avatarUrl,
    this.selected = false,
    this.isAny = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.brass : Colors.transparent,
            width: 2,
          ),
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
            _Avatar(name: name, avatarUrl: avatarUrl, isAny: isAny),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.brass, size: 22),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isAny;

  const _Avatar({required this.name, required this.avatarUrl, required this.isAny});

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: isAny
          ? const Icon(Icons.people_outline, color: Colors.white, size: 22)
          : Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    final url = avatarUrl;
    if (url == null) return fallback;

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, image) =>
          CircleAvatar(radius: radius, backgroundImage: image),
      placeholder: (context, _) => fallback,
      errorWidget: (context, _, __) => fallback,
    );
  }
}
