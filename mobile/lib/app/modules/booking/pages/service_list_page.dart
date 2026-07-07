import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/selectable_card.dart';
import '../booking_controller.dart';

class ServiceListPage extends GetView<BookingController> {
  const ServiceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What would you like?')),
      body: Obx(() {
        if (controller.servicesLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.servicesError.value != null) {
          return _ErrorRetry(
            message: controller.servicesError.value!,
            onRetry: controller.loadServices,
          );
        }

        if (controller.services.isEmpty) {
          return const Center(child: Text('No services available right now.'));
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: controller.services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final service = controller.services[i];
            return Obx(
              () => SelectableCard(
                selected: controller.selectedService.value?.id == service.id,
                onTap: () => controller.selectService(service),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service.formattedDuration,
                            style: const TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      service.formattedPrice,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brass),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: AppColors.late)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
