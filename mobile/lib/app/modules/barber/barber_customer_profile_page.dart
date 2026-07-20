import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import 'barber_customer_profile_controller.dart';
import 'models/customer_visit_entry.dart';
import 'models/staff_customer_profile_model.dart';

/// The barber's read-only "Customer Profile" screen — contact info, this
/// staff member's visit timeline with the client, and both note fields.
/// Per BARBER-APP.md's "Customer Profile" section and Slice 5 of
/// docs/superpowers/specs/2026-07-18-barber-workspace-design.md.
///
/// Notes are display-only here, unlike BarberAppointmentDetailPage's
/// editable Customer Notes / Barber Notes sections: this slice's backend
/// contract has no PATCH endpoint for the customer-profile screen (only
/// PATCH /v1/staff/bookings/[id], scoped to a single booking) — see
/// StaffCustomerProfileModel's doc comment. Visual structure (icon,
/// title, "visible to staff" vs "private" subtitle, card styling)
/// otherwise matches that screen's notes sections so the two audiences
/// read the same way everywhere they appear.
class BarberCustomerProfilePage extends StatefulWidget {
  final String customerId;

  const BarberCustomerProfilePage({super.key, required this.customerId});

  @override
  State<BarberCustomerProfilePage> createState() =>
      _BarberCustomerProfilePageState();
}

class _BarberCustomerProfilePageState
    extends State<BarberCustomerProfilePage> {
  late final BarberCustomerProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      BarberCustomerProfileController(widget.customerId),
      tag: widget.customerId,
    );
  }

  @override
  void dispose() {
    Get.delete<BarberCustomerProfileController>(tag: widget.customerId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer')),
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value && controller.profile.value == null) {
            return const _ProfileSkeleton();
          }

          final profile = controller.profile.value;
          if (profile == null) {
            if (controller.notServed.value) {
              return ListView(
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  EmptyState(
                    icon: Icons.lock_outline,
                    title: "Can't view this customer",
                    subtitle:
                        controller.loadError.value ??
                        "You haven't served this client yet.",
                  ),
                ],
              );
            }
            return ListView(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                EmptyState(
                  icon: Icons.cloud_off,
                  title: "Couldn't load this customer",
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
              _ProfileHeader(profile: profile),
              const SizedBox(height: AppSpacing.md),
              _NotesCard(
                title: 'Customer Notes',
                icon: Icons.visibility_outlined,
                subtitle: 'Visible to staff',
                emptyPlaceholder: 'No customer notes yet.',
                value: profile.customerNotes,
              ),
              const SizedBox(height: AppSpacing.md),
              _NotesCard(
                title: 'Staff Notes',
                icon: Icons.lock_outline,
                subtitle: 'Private — only you can see this',
                emptyPlaceholder: 'No private notes yet.',
                value: profile.staffNotes,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Visit History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (profile.visits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'No visits recorded yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                _VisitTimeline(visits: profile.visits),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final StaffCustomerProfileModel profile;

  const _ProfileHeader({required this.profile});

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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.navy,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(profile.phone, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(profile.visitCountLabel, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only notes display — see this file's top doc comment for why
/// there's no edit affordance here, unlike
/// BarberAppointmentDetailPage._NotesSection. Same card chrome (icon,
/// title, subtitle, shadowed container) as that screen's notes sections
/// so Customer Notes / Barber Notes look identical wherever they appear
/// in the app.
class _NotesCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final String emptyPlaceholder;
  final String? value;

  const _NotesCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.emptyPlaceholder,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = (value ?? '').isNotEmpty;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasValue ? value! : emptyPlaceholder,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visit timeline per BARBER-APP.md's "Customer Profile" example (date +
/// services, divided rows). Not AppointmentTimelineCard: that widget is
/// bound to StaffAppointmentModel (scheduled time, client name, a status
/// chip) for the Dashboard/Schedule appointment lists — a shape that
/// doesn't fit a completed past visit's simpler (date, services) pair,
/// and repeating the client's own name on every row of their own profile
/// would be redundant. This reuses the same dot-and-rail visual language
/// instead, for consistency with the rest of the app's timelines.
class _VisitTimeline extends StatelessWidget {
  final List<CustomerVisitEntry> visits;

  const _VisitTimeline({required this.visits});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < visits.length; i++)
          _VisitRow(visit: visits[i], isLast: i == visits.length - 1),
      ],
    );
  }
}

class _VisitRow extends StatelessWidget {
  final CustomerVisitEntry visit;
  final bool isLast;

  const _VisitRow({required this.visit, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(visit.date)?.toLocal();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.brass,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.brass.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date != null ? DateFormat('MMMM d').format(date) : visit.date,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(visit.servicesLabel, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(height: 96),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 100),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 100),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 160),
      ],
    );
  }
}
