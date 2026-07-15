import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'shell_controller.dart';

class ShellPage extends GetView<ShellController> {
  const ShellPage({super.key});

  static const _tabs = [
    _ShellTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _ShellTab(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Book'),
    _ShellTab(icon: Icons.event_note_outlined, activeIcon: Icons.event_note, label: 'Appointments'),
    _ShellTab(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
    _ShellTab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentTab.value,
          children: const [
            _PlaceholderTab(
              title: 'Home',
              subtitle: 'Your personalized dashboard is on the way.',
            ),
            _BookTab(),
            _PlaceholderTab(
              title: 'Appointments',
              subtitle: 'View, reschedule, and cancel your bookings here soon.',
            ),
            _PlaceholderTab(
              title: 'Explore',
              subtitle: 'Discover professionals, styles, and inspiration — coming soon.',
            ),
            _PlaceholderTab(
              title: 'Profile',
              subtitle: 'Your profile is on the way.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ShellBottomBar(tabs: _tabs, controller: controller),
    );
  }
}

class _ShellTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _ShellTab({required this.icon, required this.activeIcon, required this.label});
}

/// Deliberately not a stock BottomNavigationBar/NavigationBar — a rounded,
/// floating pill bar with a highlighted active item, per the design brief's
/// instruction to look distinct from the platform default.
class _ShellBottomBar extends StatelessWidget {
  final List<_ShellTab> tabs;
  final ShellController controller;

  const _ShellBottomBar({required this.tabs, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.currentTab.value;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusLg),
            topRight: Radius.circular(AppSpacing.radiusLg),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _ShellNavButton(
                  tab: tabs[i],
                  selected: i == active,
                  onTap: () => controller.changeTab(i),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _ShellNavButton extends StatelessWidget {
  final _ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _ShellNavButton({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brassLight : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standing in for Home/Appointments/Explore/Profile until each lands its
/// own module — removed as each tab gets its real page.
class _PlaceholderTab extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlaceholderTab({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top, size: 40, color: AppColors.brass),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookTab extends StatelessWidget {
  const _BookTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book an appointment')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.content_cut, size: 48, color: AppColors.brass),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ready when you are',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              "Pick a service, choose your favorite professional, and grab a time that works for you.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => Get.toNamed(AppRoutes.bookCategory),
              child: const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}
