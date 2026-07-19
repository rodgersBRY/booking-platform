import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import 'barber_profile_controller.dart';

/// The barber workspace's Profile tab: avatar, name, role, and logout.
/// Visually mirrors the customer ProfilePage (modules/profile/) — same
/// header layout, section card, and destructive-tile treatment — with
/// staff-relevant content instead of customer account data.
class BarberProfilePage extends GetView<BarberProfileController> {
  const BarberProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonList(count: 3, itemHeight: 56);
        }

        final staff = controller.staff.value;
        if (staff == null) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load your profile',
            subtitle: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: controller.load,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _BarberProfileHeader(
              name: staff.name,
              role: staff.role,
              avatarUrl: staff.avatarUrl,
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.logout,
                    label: 'Logout',
                    isLast: true,
                    destructive: true,
                    onTap: () => _confirmSignOut(context),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text(
              "You'll need to sign in again to access your workspace.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.signOut();
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
    );
  }
}

class _BarberProfileHeader extends StatelessWidget {
  final String name;
  final String role;
  final String? avatarUrl;

  const _BarberProfileHeader({
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static const _roleLabels = {
    'barber': 'Barber',
    'beautician': 'Beautician',
    'masseuse': 'Masseuse',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(initials: _initials, avatarUrl: avatarUrl),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                _roleLabels[role] ?? role,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;

  const _Avatar({required this.initials, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    const radius = 32.0;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final url = avatarUrl;
    if (url == null || url.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder:
          (context, image) =>
              CircleAvatar(radius: radius, backgroundImage: image),
      placeholder: (context, _) => fallback,
      errorWidget: (context, _, __) => fallback,
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;
  final bool destructive;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        destructive ? AppColors.late : theme.textTheme.bodyMedium?.color;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          trailing:
              destructive
                  ? null
                  : Icon(
                    Icons.chevron_right,
                    color: theme.textTheme.bodySmall?.color,
                  ),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
