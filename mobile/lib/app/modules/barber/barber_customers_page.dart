import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/search_bar.dart';
import 'barber_customer_profile_page.dart';
import 'barber_customers_controller.dart';
import 'models/staff_customer_model.dart';

/// The barber workspace's Customers tab — a searchable list of clients
/// this staff member has personally served, per BARBER-APP.md's
/// Customers section. Replaces the ComingSoonPage placeholder from
/// Slices 1-2.
class BarberCustomersPage extends GetView<BarberCustomersController> {
  const BarberCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: AppSearchBar(
                  controller: controller.searchController,
                  hintText: 'Search by name or phone',
                  autofocus: false,
                  onChanged: controller.onQueryChanged,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshCustomers,
                  child: Obx(() {
                    if (controller.loading.value &&
                        controller.customers.isEmpty) {
                      return const SkeletonList(count: 6, itemHeight: 76);
                    }

                    if (controller.customers.isEmpty) {
                      final error = controller.loadError.value;
                      if (error != null) {
                        return ListView(
                          children: [
                            const SizedBox(height: AppSpacing.xxl),
                            EmptyState(
                              icon: Icons.cloud_off,
                              title: "Couldn't load your customers",
                              subtitle: error,
                              actionLabel: 'Retry',
                              onAction: controller.refreshCustomers,
                            ),
                          ],
                        );
                      }

                      if (controller.query.value.trim().isNotEmpty) {
                        return ListView(
                          children: [
                            const SizedBox(height: AppSpacing.xxl),
                            const EmptyState(
                              icon: Icons.person_search,
                              title: 'No matches',
                              subtitle:
                                  'No customers match your search. Try a different name or phone number.',
                            ),
                          ],
                        );
                      }

                      return ListView(
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          const EmptyState(
                            icon: Icons.people_outline,
                            title: 'No customers yet',
                            subtitle:
                                'Customers you have served will appear here.',
                          ),
                        ],
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        if (controller.refreshError.value != null) ...[
                          _RefreshErrorBanner(
                            message: controller.refreshError.value!,
                            onRetry: controller.refreshCustomers,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        for (final customer in controller.customers)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm + 4,
                            ),
                            child: _CustomerCard(
                              customer: customer,
                              onTap:
                                  () => Get.to(
                                    () => BarberCustomerProfilePage(
                                      customerId: customer.id,
                                    ),
                                  ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final StaffCustomerModel customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastVisit = DateTime.tryParse(customer.lastVisitAt)?.toLocal();

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
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
                backgroundColor: AppColors.navy,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(customer.visitCountLabel, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      lastVisit != null
                          ? 'Last Visit · ${relativeDateLabel(lastVisit)}'
                          : 'Last Visit · Unknown',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RefreshErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.lateBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.late, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.late, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
