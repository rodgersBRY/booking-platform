import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/booking_progress_indicator.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/skeleton_loader.dart';
import '../booking_controller.dart';

class SlotPage extends GetView<BookingController> {
  const SlotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dates = controller.nextDates(14);

    return Scaffold(
      appBar: AppBar(title: const Text('Pick a date and time')),
      body: Column(
        children: [
          const BookingProgressIndicator(current: BookingStep.time),
          SizedBox(
            height: 72,
            child: Obx(() {
              final activeDate = controller.activeDate.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: dates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final date = dates[i];
                  final parsed = DateTime.parse(date);
                  final active = activeDate == date;
                  return InkWell(
                    onTap: () => controller.loadSlots(date),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? AppColors.brass : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              active
                                  ? AppColors.brass
                                  : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(parsed),
                            style: TextStyle(
                              fontSize: 12,
                              color: active ? Colors.white : AppColors.navy,
                            ),
                          ),
                          Text(
                            '${parsed.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: active ? Colors.white : AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.slotsLoading.value) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SkeletonList(count: 4, itemHeight: 48),
                );
              }
              if (controller.slotsError.value != null) {
                final date = controller.activeDate.value;
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
                  subtitle: 'Try another date — mornings usually open up first.',
                );
              }
              final selectedStart = controller.selectedSlot.value?.start;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
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
                      backgroundColor:
                          selected ? AppColors.brass : AppColors.card,
                      foregroundColor: selected ? Colors.white : AppColors.navy,
                      side: BorderSide(
                        color:
                            selected
                                ? AppColors.brass
                                : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      slot.label,
                      style: const TextStyle(fontSize: 13),
                    ),
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
