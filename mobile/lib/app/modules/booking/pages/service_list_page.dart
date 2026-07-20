import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_spacing.dart';
import '../../../utils/format.dart';
import '../../../widgets/booking_progress_indicator.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/service_card.dart';
import '../../../widgets/skeleton_loader.dart';
import '../booking_controller.dart';

class ServiceListPage extends GetView<BookingController> {
  const ServiceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(categoryLabel(controller.selectedCategory.value ?? '')),
        ),
      ),
      body: Column(
        children: [
          BookingProgressIndicator(
            currentStep: BookingStep.service.index,
            totalSteps: BookingStep.values.length,
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
              final services = controller.servicesInSelectedCategory;
              if (services.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_busy,
                  title: 'Nothing here right now',
                  subtitle: 'No services in this category at the moment.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: services.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm + 4),
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
