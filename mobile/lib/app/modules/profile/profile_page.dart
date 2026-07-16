import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../services/theme_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/coming_soon_page.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../shell/shell_controller.dart';
import 'profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonList(count: 4, itemHeight: 56);
        }
        final client = controller.client.value;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (client != null) ...[
              _ProfileHeader(name: client.name, phone: client.phone, email: client.email),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                children: [
                  _ProfileTile(
                    icon: Icons.event_note_outlined,
                    label: 'My Appointments',
                    onTap: () => Get.find<ShellController>()
                        .changeTab(appointmentsTabIndex),
                  ),
                  _ProfileTile(
                    icon: Icons.favorite_border,
                    label: 'Favorite Professionals',
                    onTap: () => _openComingSoon(
                      context,
                      icon: Icons.favorite_border,
                      title: 'Favorite Professionals',
                    ),
                  ),
                  _ProfileTile(
                    icon: Icons.content_cut,
                    label: 'Favorite Services',
                    onTap: () => _openComingSoon(
                      context,
                      icon: Icons.content_cut,
                      title: 'Favorite Services',
                    ),
                  ),
                  _ProfileTile(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Saved Inspiration',
                    isLast: true,
                    onTap: () => _openComingSoon(
                      context,
                      icon: Icons.auto_awesome_outlined,
                      title: 'Saved Inspiration',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ] else ...[
              EmptyState(
                icon: Icons.person_outline,
                title: 'Sign in to your account',
                subtitle: 'Track your bookings and manage your profile.',
                actionLabel: 'Sign in',
                onAction: () => Get.toNamed(AppRoutes.login),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            // App-level settings — not account data, so available whether
            // or not the client is signed in.
            _SectionCard(
              children: [
                _ProfileTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Appearance',
                  onTap: () => _showAppearancePicker(context),
                ),
                _ProfileTile(
                  icon: Icons.support_agent_outlined,
                  label: 'Help & Support',
                  onTap: () => _showHelpSheet(context),
                ),
                _ProfileTile(
                  icon: Icons.info_outline,
                  label: 'About',
                  isLast: true,
                  onTap: () => _showAboutSheet(context),
                ),
              ],
            ),
            if (client != null) ...[
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
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
            ],
          ],
        );
      }),
    );
  }

  void _openComingSoon(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    Get.to(() => ComingSoonPage(
          icon: icon,
          title: title,
          subtitle: 'Coming soon.',
          withAppBar: true,
        ));
  }

  void _showAppearancePicker(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    showDialog(
      context: context,
      builder: (context) => Obx(
        () => SimpleDialog(
          title: const Text('Appearance'),
          children: [
            _AppearanceOption(
              label: 'System',
              value: ThemeMode.system,
              groupValue: themeController.mode.value,
              onChanged: themeController.setMode,
            ),
            _AppearanceOption(
              label: 'Light',
              value: ThemeMode.light,
              groupValue: themeController.mode.value,
              onChanged: themeController.setMode,
            ),
            _AppearanceOption(
              label: 'Dark',
              value: ThemeMode.dark,
              groupValue: themeController.mode.value,
              onChanged: themeController.setMode,
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Help & Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: AppSpacing.md),
            _ContactRow(icon: Icons.call_outlined, label: 'Call the shop'),
            SizedBox(height: AppSpacing.sm + 4),
            _ContactRow(icon: Icons.chat_outlined, label: 'Message us on WhatsApp'),
          ],
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Baberia Cuts',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Your grooming and wellness companion.',
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text("You'll need to sign in again to see your bookings."),
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

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String? email;

  const _ProfileHeader({required this.name, required this.phone, this.email});

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.navy,
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(phone, style: Theme.of(context).textTheme.bodySmall),
              if (email != null && email!.isNotEmpty)
                Text(email!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
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
    final color = destructive ? AppColors.late : AppColors.navy;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          trailing: destructive
              ? null
              : const Icon(Icons.chevron_right, color: Colors.black26),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  const _AppearanceOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (m) => onChanged(m!),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brass),
        const SizedBox(width: AppSpacing.sm + 4),
        Text(label),
      ],
    );
  }
}
