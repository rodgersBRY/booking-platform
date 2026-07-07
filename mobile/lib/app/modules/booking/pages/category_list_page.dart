import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/format.dart';
import '../../../widgets/selectable_card.dart';
import '../booking_controller.dart';

class CategoryListPage extends GetView<BookingController> {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What are you after?')),
      body: Obx(() {
        if (controller.servicesLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.servicesError.value != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.servicesError.value!, style: const TextStyle(color: AppColors.late)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: controller.loadServices, child: const Text('Retry')),
              ],
            ),
          );
        }
        final categories = controller.categories;
        if (categories.isEmpty) {
          return const Center(child: Text('No services available right now.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final category = categories[i];
            return Obx(
              () => SelectableCard(
                selected: controller.selectedCategory.value == category,
                onTap: () => controller.selectCategory(category),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryLabel(category),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black26),
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
