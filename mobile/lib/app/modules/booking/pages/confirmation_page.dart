import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../booking_controller.dart';

class ConfirmationPage extends GetView<BookingController> {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = controller.selectedService.value;
    final slot = controller.selectedSlot.value;
    final barberId = controller.selectedBarberId.value;
    final barberName = barberId == anyBarberId
        ? (controller.barbers
                  .firstWhereOrNull((b) => b.id == slot?.barberId)
                  ?.name ??
              'Your barber')
        : (controller.barbers.firstWhereOrNull((b) => b.id == barberId)?.name ??
              'Your barber');

    final dateLabel = slot != null
        ? DateFormat('EEEE, d MMMM').format(DateTime.parse(slot.start))
        : '';

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Booked!')),
      body: Padding(
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
                    _SummaryRow('With', barberName),
                    _SummaryRow('Date', dateLabel),
                    _SummaryRow('Time', slot?.label ?? ''),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
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
