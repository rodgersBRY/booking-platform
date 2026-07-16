import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_spacing.dart';
import '../../../utils/format.dart';
import '../../../widgets/booking_progress_indicator.dart';
import '../../../widgets/category_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/skeleton_loader.dart';
import '../booking_controller.dart';

class CategoryListPage extends GetView<BookingController> {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What are you after?')),
      body: Column(
        children: [
          const BookingProgressIndicator(current: BookingStep.category),
          Expanded(
            child: Obx(() {
              if (controller.servicesLoading.value) {
                return const SkeletonList(count: 4, itemHeight: 110);
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
              final categories = controller.categories;
              if (categories.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_busy,
                  title: 'Nothing available right now',
                  subtitle: 'Please check back a little later.',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm + 4,
                  crossAxisSpacing: AppSpacing.sm + 4,
                  childAspectRatio: 1.1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final category = categories[i];
                  return CategoryCard(
                    label: categoryLabel(category),
                    icon: categoryIcon(category),
                    onTap: () => controller.selectCategory(category),
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
