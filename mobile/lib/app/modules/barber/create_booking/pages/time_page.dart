import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../widgets/booking_progress_indicator.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/skeleton_loader.dart';
import '../barber_create_booking_controller.dart';

/// Step 4 of the barber create-booking wizard: pick a free slot on the
/// already-chosen date, for the already-chosen service.
class TimePage extends GetView<BarberCreateBookingController> {
  const TimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final date = controller.selectedDate.value;
          final label = date.isEmpty
              ? 'Pick a time'
              : DateFormat('EEEE, d MMMM').format(DateTime.parse(date));
          return Text(label);
        }),
      ),
      body: Column(
        children: [
          BookingProgressIndicator(
            currentStep: BarberBookingStep.time.index,
            totalSteps: BarberBookingStep.values.length,
          ),
          Expanded(
            child: Obx(() {
              if (controller.slotsLoading.value) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SkeletonList(count: 4, itemHeight: 48),
                );
              }
              if (controller.slotsError.value != null) {
                final date = controller.selectedDate.value;
                return EmptyState(
                  icon: Icons.cloud_off,
                  title: "Couldn't load times",
                  subtitle: controller.slotsError.value!,
                  actionLabel: 'Retry',
                  onAction: () => controller.loadSlots(date),
                );
              }
              if (controller.slots.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_busy,
                  title: 'Fully booked that day',
                  subtitle: 'Go back and try another date.',
                );
              }
              final selectedStart = controller.selectedSlot.value?.start;
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: controller.slots.length,
                itemBuilder: (context, i) {
                  final slot = controller.slots[i];
                  final selected = selectedStart == slot.start;
                  return OutlinedButton(
                    onPressed: () => controller.selectSlot(slot),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected ? AppColors.brass : AppColors.card,
                      foregroundColor: selected ? Colors.white : AppColors.navy,
                      side: BorderSide(
                        color: selected ? AppColors.brass : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(slot.label, style: const TextStyle(fontSize: 13)),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
