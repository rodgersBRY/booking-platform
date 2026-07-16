import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/booking_model.dart';
import '../../data/models/slot_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/bookings_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton_loader.dart';
import 'appointments_controller.dart';

List<String> _nextDates(int count) {
  final now = DateTime.now();
  return List.generate(count, (i) {
    final d = now.add(Duration(days: i));
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  });
}

/// Cut-down slot picker for moving an existing "booked" appointment to a
/// new time — same staff and service, reusing the same availability
/// endpoint the booking wizard uses.
class ReschedulePage extends StatefulWidget {
  final BookingModel booking;

  const ReschedulePage({super.key, required this.booking});

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  final BookingRepository _availabilityRepo = BookingRepository();
  final BookingsRepository _bookingsRepo = BookingsRepository();

  late final List<String> _dates = _nextDates(14);
  late String _activeDate = _dates.first;

  List<SlotModel> _slots = [];
  bool _slotsLoading = false;
  String? _slotsError;
  SlotModel? _selectedSlot;

  bool _submitting = false;
  String? _submitError;
  List<SlotModel>? _slotTakenSlots;

  @override
  void initState() {
    super.initState();
    _loadSlots(_activeDate);
  }

  Future<void> _loadSlots(String date) async {
    final staffId = widget.booking.staff?.id;
    final serviceId = widget.booking.service?.id;
    if (staffId == null || serviceId == null) return;

    setState(() {
      _activeDate = date;
      _slots = [];
      _slotsError = null;
      _slotsLoading = true;
      _selectedSlot = null;
    });

    try {
      final slots = await _availabilityRepo.fetchAvailability(
        staffId: staffId,
        serviceId: serviceId,
        date: date,
      );
      if (!mounted) return;
      setState(() => _slots = slots);
    } catch (_) {
      if (!mounted) return;
      setState(() => _slotsError = "Couldn't load times. Please try again.");
    } finally {
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  Future<void> _submit(SlotModel slot) async {
    setState(() {
      _submitting = true;
      _submitError = null;
      _slotTakenSlots = null;
    });

    final result = await _bookingsRepo.rescheduleBooking(
      id: widget.booking.id,
      scheduledStart: slot.start,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      if (Get.isRegistered<AppointmentsController>()) {
        Get.find<AppointmentsController>().load();
      }
      Get.back();
      Get.snackbar('Appointment rescheduled', 'See you then.');
      return;
    }

    setState(() {
      _submitError =
          result.message ?? 'Something went wrong. Please try again.';
      _slotTakenSlots = result.slots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule')),
      body: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final date = _dates[i];
                final parsed = DateTime.parse(date);
                final active = _activeDate == date;
                return InkWell(
                  onTap: () => _loadSlots(date),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    width: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.brass : AppColors.card,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: active ? AppColors.brass : const Color(0xFFE5E7EB),
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
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildSlots()),
          if (_submitError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(_submitError!, style: const TextStyle(color: AppColors.late)),
            ),
          if (_slotTakenSlots != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _slotTakenSlots!
                    .map((s) => OutlinedButton(
                          onPressed: () => _submit(s),
                          child: Text(s.label),
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: PrimaryButton(
              label: 'Confirm new time',
              busy: _submitting,
              onPressed: _selectedSlot == null ? null : () => _submit(_selectedSlot!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlots() {
    if (_slotsLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: SkeletonList(count: 4, itemHeight: 48),
      );
    }
    if (_slotsError != null) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: "Couldn't load times",
        subtitle: _slotsError!,
        actionLabel: 'Retry',
        onAction: () => _loadSlots(_activeDate),
      );
    }
    if (_slots.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy,
        title: 'Fully booked that day',
        subtitle: 'Try another date.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: _slots.length,
      itemBuilder: (context, i) {
        final slot = _slots[i];
        final selected = _selectedSlot?.start == slot.start;
        return OutlinedButton(
          onPressed: () => setState(() => _selectedSlot = slot),
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
  }
}
