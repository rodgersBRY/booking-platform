import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../widgets/booking_progress_indicator.dart';
import '../../../../widgets/primary_button.dart';
import '../barber_create_booking_controller.dart';

/// Step 5 of the barber create-booking wizard: review everything chosen,
/// then Confirm — the "Review, Confirm" pair from the design spec's step
/// list collapse into this single page (see submit()'s doc comment: the
/// wizard jumps straight to the new booking's own detail page on success,
/// with no separate "Booked!" screen).
class ReviewPage extends GetView<BarberCreateBookingController> {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingProgressIndicator(
              currentStep: BarberBookingStep.review.index,
              totalSteps: BarberBookingStep.values.length,
            ),
            const SizedBox(height: AppSpacing.sm),
            Obx(() {
              final client = controller.selectedClient.value;
              final service = controller.selectedService.value;
              final slot = controller.selectedSlot.value;
              final dateLabel = slot != null
                  ? DateFormat('EEEE, d MMMM').format(DateTime.parse(slot.start))
                  : '';
              return _SummaryCard(
                clientName: client?.name ?? '',
                clientPhone: client?.phone ?? '',
                serviceName: service?.name ?? '',
                dateLabel: dateLabel,
                timeLabel: slot?.label ?? '',
                duration: service?.formattedDuration ?? '',
                total: service?.formattedPrice ?? '',
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => PrimaryButton(
                label: 'Confirm booking',
                busy: controller.submitting.value,
                onPressed: controller.submit,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(() {
              if (controller.submitError.value == null) {
                return const SizedBox.shrink();
              }
              return Text(
                controller.submitError.value!,
                style: const TextStyle(color: AppColors.late),
              );
            }),
            Obx(() {
              final retrySlots = controller.slotTakenSlots.value;
              if (retrySlots == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm + 4),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
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

class _SummaryCard extends StatelessWidget {
  final String clientName;
  final String clientPhone;
  final String serviceName;
  final String dateLabel;
  final String timeLabel;
  final String duration;
  final String total;

  const _SummaryCard({
    required this.clientName,
    required this.clientPhone,
    required this.serviceName,
    required this.dateLabel,
    required this.timeLabel,
    required this.duration,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        child: Column(
          children: [
            _SummaryRow('Client', '$clientName · $clientPhone'),
            _SummaryRow('Service', serviceName),
            _SummaryRow('Date', dateLabel),
            _SummaryRow('Time', timeLabel),
            _SummaryRow('Duration', duration),
            const Divider(height: AppSpacing.lg),
            _SummaryRow('Total', total, emphasized: true),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _SummaryRow(this.label, this.value, {this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: emphasized
                  ? const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.brass,
                    )
                  : theme.textTheme.titleMedium?.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
