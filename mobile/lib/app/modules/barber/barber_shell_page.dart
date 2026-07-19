import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/app_bottom_nav_bar.dart';
import '../../widgets/coming_soon_page.dart';
import 'barber_dashboard_page.dart';
import 'barber_profile_page.dart';
import 'barber_schedule_page.dart';
import 'barber_shell_controller.dart';

/// The barber workspace's shell — mirrors ShellPage's structure (an
/// IndexedStack of tabs behind the shared bottom nav bar) with the barber
/// tab set: Dashboard, Schedule, Customers, Notifications, Profile.
/// Customers/Notifications are placeholders in this slice; Dashboard,
/// Schedule, and Profile are wired to real data.
class BarberShellPage extends GetView<BarberShellController> {
  const BarberShellPage({super.key});

  static const _tabs = [
    AppBottomNavTab(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    AppBottomNavTab(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Schedule',
    ),
    AppBottomNavTab(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Customers',
    ),
    AppBottomNavTab(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      label: 'Notifications',
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
            BarberDashboardPage(),
            BarberSchedulePage(),
            ComingSoonPage(
              icon: Icons.people_outline,
              title: 'Customers',
              subtitle: 'Customers you have served will appear here.',
            ),
            ComingSoonPage(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: "You're all caught up.",
            ),
            BarberProfilePage(),
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
