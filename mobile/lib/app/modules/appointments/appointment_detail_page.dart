import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/booking_model.dart';
import '../../data/repositories/bookings_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/status_chip.dart';
import '../booking/booking_binding.dart';
import '../booking/booking_controller.dart';
import 'appointments_controller.dart';
import 'reschedule_page.dart';

class AppointmentDetailPage extends StatefulWidget {
  final BookingModel booking;

  const AppointmentDetailPage({super.key, required this.booking});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final BookingsRepository _repo = BookingsRepository();
  bool _cancelling = false;

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This can\'t be undone. You\'ll need to book again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    final result = await _repo.cancelBooking(widget.booking.id);
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (result.success) {
      if (Get.isRegistered<AppointmentsController>()) {
        Get.find<AppointmentsController>().load();
      }
      Get.back();
      Get.snackbar('Appointment cancelled', 'See you next time.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ?? 'Something went wrong. Please try again.',
        ),
      ),
    );
  }

  void _bookAgain() {
    final service = widget.booking.service;
    if (service == null) return;
    if (!Get.isRegistered<BookingController>()) {
      BookingBinding().dependencies();
    }
    Get.find<BookingController>().bookAgain(service);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final start = DateTime.parse(booking.scheduledStart).toLocal();
    final canBookAgain =
        !booking.canCancel && !booking.canReschedule && booking.service != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.service?.name ?? 'Appointment',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 4),
                child: Column(
                  children: [
                    _Row('Professional', booking.staff?.name ?? 'Not assigned'),
                    _Row('Date', DateFormat('EEEE, d MMMM').format(start)),
                    _Row('Time', DateFormat('h:mm a').format(start)),
                    if (booking.service != null)
                      _Row('Duration', booking.service!.formattedDuration),
                    if (booking.service != null)
                      _Row('Price', booking.service!.formattedPrice, emphasized: true),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (booking.canReschedule)
              SecondaryButton(
                label: 'Reschedule',
                onPressed: () => Get.to(() => ReschedulePage(booking: booking)),
              ),
            if (booking.canReschedule) const SizedBox(height: AppSpacing.sm + 4),
            if (booking.canCancel)
              PrimaryButton(
                label: 'Cancel appointment',
                busy: _cancelling,
                onPressed: _confirmCancel,
              ),
            if (canBookAgain)
              PrimaryButton(label: 'Book again', onPressed: _bookAgain),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _Row(this.label, this.value, {this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: emphasized
                ? const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.brass,
                  )
                : Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
