import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format.dart';
import '../../widgets/category_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/service_card.dart';
import '../../widgets/skeleton_loader.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonList(count: 5, itemHeight: 96);
            }
            if (controller.error.value != null) {
              return ListView(
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  EmptyState(
                    icon: Icons.cloud_off,
                    title: "Couldn't load",
                    subtitle: controller.error.value!,
                    actionLabel: 'Retry',
                    onAction: controller.load,
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const _Header(),
                const SizedBox(height: AppSpacing.lg),
                const _BookHero(),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle('Quick categories'),
                const SizedBox(height: AppSpacing.sm + 4),
                const _CategoryStrip(),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle('Our professionals'),
                const SizedBox(height: AppSpacing.sm + 4),
                const _ProfessionalStrip(),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle('Our services'),
                const SizedBox(height: AppSpacing.sm + 4),
                const _ServicePreviewList(),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Header extends GetView<HomeController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final client = controller.client.value;
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.greeting, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  client?.name ?? 'Welcome',
                  style: theme.textTheme.displaySmall,
                ),
              ],
            ),
          ),
          if (client == null)
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.login),
              child: const Text('Sign in'),
            ),
        ],
      );
    });
  }
}

/// The one clear primary action on this screen.
class _BookHero extends StatelessWidget {
  const _BookHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Look sharp, feel great',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Grab a spot with your favorite professional.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.bookCategory),
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _CategoryStrip extends GetView<HomeController> {
  const _CategoryStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Obx(() {
        final categories = controller.categories;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm + 4),
          itemBuilder: (context, i) {
            final category = categories[i];
            return SizedBox(
              width: 140,
              child: CategoryCard(
                label: categoryLabel(category),
                icon: categoryIcon(category),
                onTap: () => controller.openCategory(category),
              ),
            );
          },
        );
      }),
    );
  }
}

class _ProfessionalStrip extends GetView<HomeController> {
  const _ProfessionalStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Obx(() {
        final staff = controller.staff;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: staff.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, i) {
            final member = staff[i];
            return _ProfessionalChip(
              role: member.role,
              name: member.name,
              avatarUrl: member.avatarUrl,
            );
          },
        );
      }),
    );
  }
}

class _ProfessionalChip extends StatelessWidget {
  final String name;
  final String role;
  final String? avatarUrl;

  const _ProfessionalChip({
    required this.name,
    required this.role,
    required this.avatarUrl,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 32.0;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final url = avatarUrl;

    return SizedBox(
      width: 76,
      child: Column(
        children: [
          url == null
              ? fallback
              : CachedNetworkImage(
                imageUrl: url,
                imageBuilder:
                    (context, image) =>
                        CircleAvatar(radius: radius, backgroundImage: image),
                placeholder: (context, _) => fallback,
                errorWidget: (context, _, __) => fallback,
              ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            name.split(' ').first,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '~ ${role.capitalize} ~',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _ServicePreviewList extends GetView<HomeController> {
  const _ServicePreviewList();

  static const _previewCount = 4;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.services.take(_previewCount).toList();
      return Column(
        children: [
          for (final service in preview)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
              child: ServiceCard(
                service: service,
                onTap: () => controller.openService(service),
              ),
            ),
          if (controller.services.length > _previewCount)
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.bookCategory),
              child: const Text('See all services'),
            ),
        ],
      );
    });
  }
}
