import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../booking_controller.dart';

class DetailsPage extends GetView<BookingController> {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'First name'),
              onChanged: (v) => controller.name.value = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
              onChanged: (v) => controller.phone.value = v,
            ),
            const SizedBox(height: 24),
            Obx(
              () => ElevatedButton(
                onPressed: controller.submitting.value ? null : controller.submit,
                child: Text(controller.submitting.value ? 'Booking…' : 'Confirm booking'),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.submitError.value == null) return const SizedBox.shrink();
              return Text(
                controller.submitError.value!,
                style: const TextStyle(color: AppColors.late),
              );
            }),
            Obx(() {
              final retrySlots = controller.slotTakenSlots.value;
              if (retrySlots == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: retrySlots
                      .map(
                        (slot) => OutlinedButton(
                          onPressed: () => controller.retrySlot(slot),
                          child: Text(slot.label),
                        ),
                      )
                      .toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
