import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/booking_progress_indicator.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/professional_card.dart';
import '../../../widgets/skeleton_loader.dart';
import '../booking_controller.dart';

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class StaffListPage extends GetView<BookingController> {
  const StaffListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who would you like?')),
      body: Column(
        children: [
          BookingProgressIndicator(
            currentStep: BookingStep.professional.index,
            totalSteps: BookingStep.values.length,
          ),
          Expanded(
            child: Obx(() {
              if (controller.staffLoading.value) {
                return const SkeletonList(count: 4, itemHeight: 84);
              }
              if (controller.staffError.value != null) {
                return EmptyState(
                  icon: Icons.cloud_off,
                  title: "Couldn't load staff",
                  subtitle: controller.staffError.value!,
                  actionLabel: 'Retry',
                  onAction: controller.loadStaffForSelectedService,
                );
              }
              if (controller.staff.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'No one available',
                  subtitle:
                      'No staff can take this service right now — please try again later.',
                );
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Obx(
                    () => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                      child: ProfessionalCard(
                        name: _capitalize(controller.anyStaffLabel),
                        subtitle: "We'll pick whoever is free",
                        isAny: true,
                        selected:
                            controller.selectedStaffId.value == anyStaffId,
                        onTap: () => controller.selectStaff(anyStaffId),
                      ),
                    ),
                  ),
                  ...controller.staff.map(
                    (member) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                      child: Obx(
                        () => ProfessionalCard(
                          name: member.name,
                          subtitle: _capitalize(member.role),
                          avatarUrl: member.avatarUrl,
                          selected:
                              controller.selectedStaffId.value == member.id,
                          onTap: () => controller.selectStaff(member.id),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
