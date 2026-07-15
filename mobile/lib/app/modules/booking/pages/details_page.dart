import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/format.dart';
import '../../../widgets/booking_progress_indicator.dart';
import '../../../widgets/primary_button.dart';
import '../booking_controller.dart';

/// Review step: everything the client chose, plus their contact details
/// and the final confirm action.
class DetailsPage extends GetView<BookingController> {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review your booking')),
      body: GestureDetector(
        // Dismiss the keyboard when tapping outside the focused field.
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BookingProgressIndicator(current: BookingStep.review),
              const SizedBox(height: AppSpacing.sm),
              Obx(() => _SummaryCard(controller: controller)),
              const SizedBox(height: AppSpacing.lg),
              Text('Your details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm + 4),
              TextField(
                decoration: const InputDecoration(labelText: 'First name'),
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => controller.name.value = v,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
                onChanged: (v) => controller.phone.value = v,
              ),
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
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BookingController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final service = controller.selectedService.value;
    final slot = controller.selectedSlot.value;
    final staffId = controller.selectedStaffId.value;
    final staffName = staffId == anyStaffId
        ? (controller.staff
                .firstWhereOrNull((s) => s.id == slot?.staffId)
                ?.name ??
            'First available')
        : (controller.staff.firstWhereOrNull((s) => s.id == staffId)?.name ??
            '');
    final dateLabel = slot != null
        ? DateFormat('EEEE, d MMMM').format(DateTime.parse(slot.start))
        : '';
    final category = controller.selectedCategory.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        child: Column(
          children: [
            if (category != null)
              _SummaryRow('Category', categoryLabel(category)),
            _SummaryRow('Service', service?.name ?? ''),
            _SummaryRow('Professional', staffName),
            _SummaryRow('Date', dateLabel),
            _SummaryRow('Time', slot?.label ?? ''),
            _SummaryRow('Duration', service?.formattedDuration ?? ''),
            const Divider(height: AppSpacing.lg),
            _SummaryRow('Total', service?.formattedPrice ?? '', emphasized: true),
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
          Text(
            value,
            style: emphasized
                ? const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.brass,
                  )
                : theme.textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
