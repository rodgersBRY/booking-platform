import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
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
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.slotsError.value != null) {
                return Center(
                  child: Text(
                    controller.slotsError.value!,
                    style: const TextStyle(color: AppColors.late),
                  ),
                );
              }
              if (controller.slots.isEmpty) {
                return const Center(
                  child: Text(
                    'No times left on that day — try another date.',
                    style: TextStyle(color: Colors.black45),
                  ),
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
