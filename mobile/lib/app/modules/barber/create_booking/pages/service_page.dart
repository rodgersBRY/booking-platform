import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../widgets/booking_progress_indicator.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/service_card.dart';
import '../../../../widgets/skeleton_loader.dart';
import '../barber_create_booking_controller.dart';

/// Step 2 of the barber create-booking wizard: pick the service, already
/// filtered server-side to this barber's own role.
class ServicePage extends GetView<BarberCreateBookingController> {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What service?')),
      body: Column(
        children: [
          BookingProgressIndicator(
            currentStep: BarberBookingStep.service.index,
            totalSteps: BarberBookingStep.values.length,
          ),
          Expanded(
            child: Obx(() {
              if (controller.servicesLoading.value) {
                return const SkeletonList(count: 5, itemHeight: 78);
              }
              if (controller.servicesError.value != null) {
                return EmptyState(
                  icon: Icons.cloud_off,
                  title: "Couldn't load services",
                  subtitle: controller.servicesError.value!,
                  actionLabel: 'Retry',
                  onAction: controller.loadServices,
                );
              }
              final services = controller.services;
              if (services.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_busy,
                  title: 'No services available',
                  subtitle: 'Nothing is set up for your role yet.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: services.length,
                separatorBuilder:
                    (_, __) => const SizedBox(height: AppSpacing.sm + 4),
                itemBuilder: (context, i) {
                  final service = services[i];
                  return Obx(
                    () => ServiceCard(
                      service: service,
                      selected:
                          controller.selectedService.value?.id == service.id,
                      onTap: () => controller.selectService(service),
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
