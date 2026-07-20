import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'models/booking_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import 'appointment_detail_page.dart';
import 'appointments_controller.dart';

class AppointmentsPage extends GetView<AppointmentsController> {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const SkeletonList(count: 3, itemHeight: 92);
          }
          if (!controller.signedIn.value) {
            return EmptyState(
              icon: Icons.event_note_outlined,
              title: 'Sign in to see your appointments',
              subtitle: 'Track upcoming, past, and cancelled bookings.',
              actionLabel: 'Sign in',
              onAction: () => Get.toNamed(AppRoutes.login),
            );
          }
          if (controller.error.value != null) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: "Couldn't load",
              subtitle: controller.error.value!,
              actionLabel: 'Retry',
              onAction: controller.load,
            );
          }
          // Reading the RxLists here (inside the same Obx that already
          // tracks loading.value) is enough: every load()/refresh toggles
          // loading, which rebuilds this whole subtree with fresh data.
          return RefreshIndicator(
            onRefresh: controller.load,
            child: TabBarView(
              children: [
                _BookingList(
                  bookings: controller.upcoming,
                  emptyTitle: 'No upcoming appointments',
                  emptySubtitle: 'Book one now and it will show up here.',
                  emptyActionLabel: 'Book Appointment',
                  onEmptyAction: () => Get.toNamed(AppRoutes.bookCategory),
                ),
                _BookingList(
                  bookings: controller.completed,
                  emptyTitle: 'No completed appointments yet',
                  emptySubtitle: 'Your appointment history will appear here.',
                ),
                _BookingList(
                  bookings: controller.cancelled,
                  emptyTitle: 'No cancelled appointments',
                  emptySubtitle: "You haven't cancelled anything — good.",
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyTitle;
  final String emptySubtitle;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  const _BookingList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          EmptyState(
            icon: Icons.event_busy,
            title: emptyTitle,
            subtitle: emptySubtitle,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm + 4),
      itemBuilder: (context, i) {
        final booking = bookings[i];
        return AppointmentCard(
          booking: booking,
          onTap: () => Get.to(() => AppointmentDetailPage(booking: booking)),
        );
      },
    );
  }
}
