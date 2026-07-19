import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../widgets/booking_progress_indicator.dart';
import '../barber_create_booking_controller.dart';

/// Step 3 of the barber create-booking wizard: pick a date. Separate from
/// the time step (unlike the customer wizard's combined SlotPage) per the
/// design spec's explicit Customer/Service/Date/Time/Review step list.
class DatePage extends GetView<BarberCreateBookingController> {
  const DatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dates = controller.nextDates(14);

    return Scaffold(
      appBar: AppBar(title: const Text('Pick a date')),
      body: Column(
        children: [
          BookingProgressIndicator(
            currentStep: BarberBookingStep.date.index,
            totalSteps: BarberBookingStep.values.length,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: dates.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final date = dates[i];
                final parsed = DateTime.parse(date);
                return Obx(() {
                  final selected = controller.selectedDate.value == date;
                  return Material(
                    color: selected ? AppColors.brass : AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: InkWell(
                      onTap: () => controller.selectDate(date),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: selected ? AppColors.brass : const Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: selected ? Colors.white : AppColors.navy,
                            ),
                            const SizedBox(width: AppSpacing.sm + 4),
                            Text(
                              DateFormat('EEEE, d MMMM').format(parsed),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
