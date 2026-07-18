import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/professional_card.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/service_card.dart';
import '../../widgets/skeleton_loader.dart';
import 'search_controller.dart';

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class SearchPage extends GetView<AppSearchModuleController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppSearchBar(
          controller: controller.textController,
          hintText: 'Search services, professionals…',
          onChanged: (v) => controller.query.value = v,
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonList(count: 5, itemHeight: 72);
        }
        if (controller.error.value != null) {
          return EmptyState(
            icon: Icons.cloud_off,
            title: "Couldn't load",
            subtitle: controller.error.value!,
          );
        }
        if (!controller.hasQuery) {
          return const EmptyState(
            icon: Icons.search,
            title: 'Search Baberia Cuts',
            subtitle: 'Find services and professionals by name.',
          );
        }
        if (!controller.hasResults) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No matches',
            subtitle: 'Try a different search term.',
          );
        }

        final services = controller.matchedServices;
        final staff = controller.matchedStaff;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (services.isNotEmpty) ...[
              Text('Services', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm + 4),
              for (final service in services)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                  child: ServiceCard(
                    service: service,
                    onTap: () => controller.openService(service),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (staff.isNotEmpty) ...[
              Text('Professionals', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm + 4),
              for (final member in staff)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                  child: ProfessionalCard(
                    name: member.name,
                    subtitle: _capitalize(member.role),
                    avatarUrl: member.avatarUrl,
                    onTap: controller.startBooking,
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }
}
