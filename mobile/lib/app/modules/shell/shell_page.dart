import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../widgets/coming_soon_page.dart';
import '../appointments/appointments_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import 'shell_controller.dart';

class ShellPage extends GetView<ShellController> {
  const ShellPage({super.key});

  static const _tabs = [
    AppBottomNavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    AppBottomNavTab(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Book',
    ),
    AppBottomNavTab(
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note,
      label: 'Appointments',
    ),
    AppBottomNavTab(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
    ),
    AppBottomNavTab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentTab.value,
          children: const [
            HomePage(),
            _BookTab(),
            AppointmentsPage(),
            ComingSoonPage(
              icon: Icons.explore_outlined,
              title: 'Explore',
              subtitle:
                  'Discover professionals, trending services, and style inspiration. Coming soon.',
            ),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => AppBottomNavBar(
          tabs: _tabs,
          currentIndex: controller.currentTab.value,
          onTap: controller.changeTab,
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
            Text(
              "Pick a service, choose your favorite professional, and grab a time that works for you.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
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
