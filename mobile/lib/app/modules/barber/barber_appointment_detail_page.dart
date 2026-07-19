import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'barber_appointment_detail_controller.dart';
import 'models/booking_detail_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/booking_source_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_chip.dart';

/// The barber's working screen for one appointment — customer info,
/// appointment info, services, notes (customer-visible vs
/// barber-private), status, and the Start/Complete Service primary
/// action. Per docs/superpowers/specs/2026-07-18-barber-workspace-design.md
/// Slice 3 and BARBER-APP.md's "Appointment Details" section.
///
/// Fetches its own detail by [bookingId] rather than accepting an
/// already-loaded model — StaffAppointmentModel (what the Dashboard and
/// Schedule lists carry) doesn't include customer contact info, notes,
/// or the canStart/canComplete flags this screen needs.
class BarberAppointmentDetailPage extends StatefulWidget {
  final String bookingId;

  const BarberAppointmentDetailPage({super.key, required this.bookingId});

  @override
  State<BarberAppointmentDetailPage> createState() =>
      _BarberAppointmentDetailPageState();
}

class _BarberAppointmentDetailPageState
    extends State<BarberAppointmentDetailPage> {
  late final BarberAppointmentDetailController controller;

  @override
  void initState() {
    super.initState();
    // Tagged by bookingId, not a bare GetView singleton: a barber can
    // open several different bookings' details in one session and each
    // needs its own independent state.
    controller = Get.put(
      BarberAppointmentDetailController(widget.bookingId),
      tag: widget.bookingId,
    );
  }

  @override
  void dispose() {
    Get.delete<BarberAppointmentDetailController>(tag: widget.bookingId);
    super.dispose();
  }

  Future<void> _handleStart() async {
    await controller.startService();
    if (!mounted) return;
    final error = controller.actionError.value;
    if (error == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        action:
            controller.staffBusy.value
                ? SnackBarAction(label: 'Retry', onPressed: _handleStart)
                : null,
      ),
    );
  }

  Future<void> _handleComplete() async {
    final notes = await _promptServiceNotes();
    if (notes == null) return; // dismissed

    final success = await controller.completeService(
      notes: notes.isEmpty ? null : notes,
    );
    if (!mounted) return;
    if (!success) {
      final error = controller.actionError.value;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  /// Bottom sheet prompting for optional service notes before completing
  /// — BARBER-APP.md's "Primary Action" section calls this out as an
  /// "Add Service Notes" prompt tied to completion, and the backend takes
  /// them in the same POST .../complete call, so this collects them
  /// up-front rather than as a separate follow-up step.
  Future<String?> _promptServiceNotes() {
    final textController = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Service Notes',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Optional — helps you remember details for next time.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Used Number 2 guard, trimmed edges close',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                key: const Key('confirmCompleteServiceButton'),
                label: 'Complete Service',
                onPressed:
                    () => Navigator.of(
                      sheetContext,
                    ).pop(textController.text.trim()),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value && controller.booking.value == null) {
            return const _DetailSkeleton();
          }

          final booking = controller.booking.value;
          if (booking == null) {
            return ListView(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                EmptyState(
                  icon: Icons.cloud_off,
                  title: "Couldn't load this appointment",
                  subtitle:
                      controller.loadError.value ??
                      'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: controller.load,
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.client.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  StatusChip(status: booking.status),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailCard(
                title: 'Customer',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    _InfoRow('Name', booking.client.name),
                    _InfoRow('Phone', booking.client.phone),
                    _InfoRow(
                      'Visits',
                      '${booking.client.totalVisits} previous ${booking.client.totalVisits == 1 ? 'visit' : 'visits'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailCard(
                title: 'Appointment',
                icon: Icons.event_outlined,
                child: _AppointmentInfo(booking: booking),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailCard(
                title: 'Services',
                icon: Icons.content_cut,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final service in booking.services)
                      Chip(label: Text(service)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _NotesSection(
                title: 'Customer Notes',
                icon: Icons.visibility_outlined,
                subtitle: 'Visible to staff',
                emptyPlaceholder: 'No customer notes yet.',
                initialValue: booking.client.customerNotes,
                saving: controller.savingCustomerNotes,
                onSave: controller.saveCustomerNotes,
              ),
              const SizedBox(height: AppSpacing.md),
              _NotesSection(
                title: 'Staff Notes',
                icon: Icons.lock_outline,
                subtitle: 'Private — only you can see this',
                emptyPlaceholder: 'No private notes yet.',
                initialValue: booking.staffNotes,
                saving: controller.savingStaffNotes,
                onSave: controller.saveStaffNotes,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrimaryAction(
                booking: booking,
                starting: controller.starting.value,
                completing: controller.completing.value,
                onStart: _handleStart,
                onComplete: _handleComplete,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        }),
      ),
    );
  }
}

class _AppointmentInfo extends StatelessWidget {
  final BookingDetailModel booking;

  const _AppointmentInfo({required this.booking});

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(booking.scheduledStart).toLocal();
    return Column(
      children: [
        _InfoRow('Date', DateFormat('EEEE, d MMMM').format(start)),
        _InfoRow('Time', DateFormat('h:mm a').format(start)),
        _InfoRow('Duration', '${booking.durationMinutes} min'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booked via', style: Theme.of(context).textTheme.bodySmall),
              BookingSourceBadge(channel: booking.channel),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final BookingDetailModel booking;
  final bool starting;
  final bool completing;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _PrimaryAction({
    required this.booking,
    required this.starting,
    required this.completing,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (booking.canStart) {
      return PrimaryButton(
        label: 'Start Service',
        busy: starting,
        onPressed: onStart,
      );
    }
    if (booking.canComplete) {
      return PrimaryButton(
        label: 'Complete Service',
        busy: completing,
        onPressed: onComplete,
      );
    }
    return const SizedBox.shrink();
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brass),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

/// An editable notes field — used for both Customer Notes (visible to
/// staff) and Barber Notes (private), which BARBER-APP.md is explicit are
/// different audiences: [icon]/[subtitle] carry that distinction (an eye
/// vs a lock, "Visible to staff" vs "Private — only you can see this")
/// rather than leaving it to the section title alone.
class _NotesSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final String emptyPlaceholder;
  final String? initialValue;
  final RxBool saving;

  /// Returns null on success, or a user-facing error message on failure.
  final Future<String?> Function(String value) onSave;

  const _NotesSection({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.emptyPlaceholder,
    required this.initialValue,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  late final TextEditingController _textController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final error = await widget.onSave(_textController.text.trim());
    if (!mounted) return;
    if (error == null) {
      setState(() => _editing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.brass),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: theme.textTheme.titleMedium),
                    Text(widget.subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Obx(
                () =>
                    widget.saving.value
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
                          tooltip: _editing ? 'Cancel' : 'Edit',
                          onPressed: () {
                            if (_editing) {
                              _textController.text = widget.initialValue ?? '';
                            }
                            setState(() => _editing = !_editing);
                          },
                        ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_editing) ...[
            TextField(
              controller: _textController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _save, child: const Text('Save')),
            ),
          ] else
            Text(
              (widget.initialValue ?? '').isEmpty
                  ? widget.emptyPlaceholder
                  : widget.initialValue!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle:
                    (widget.initialValue ?? '').isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(height: 32, width: 200),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 120),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 140),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 80),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 100),
      ],
    );
  }
}
