import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../shell/shell_controller.dart';
import '../booking_controller.dart';

class ConfirmationPage extends GetView<BookingController> {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = controller.selectedService.value;
    final slot = controller.selectedSlot.value;
    final staffId = controller.selectedStaffId.value;
    final staffName = staffId == anyStaffId
        ? (controller.staff.firstWhereOrNull((s) => s.id == slot?.staffId)?.name ??
              'Your barber')
        : (controller.staff.firstWhereOrNull((s) => s.id == staffId)?.name ??
              'Your barber');

    final dateLabel = slot != null
        ? DateFormat('EEEE, d MMMM').format(DateTime.parse(slot.start))
        : '';

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Booked!')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.check_circle, color: AppColors.free, size: 64),
            const SizedBox(height: 16),
            const Text(
              "You're booked!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll send a reminder before your appointment.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SummaryRow('Service', service?.name ?? ''),
                    _SummaryRow('With', staffName),
                    _SummaryRow('Date', dateLabel),
                    _SummaryRow('Time', slot?.label ?? ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.brassLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get more from Baberia Cuts',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create an account to track your bookings, earn loyalty points, and book faster next time.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Get.toNamed(AppRoutes.signup),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.offAllNamed(
                AppRoutes.shell,
                arguments: {'initialTab': appointmentsTabIndex},
              ),
              child: const Text('Done'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.startOver,
              child: const Text('Book another appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
        ],
      ),
    );
  }
}
