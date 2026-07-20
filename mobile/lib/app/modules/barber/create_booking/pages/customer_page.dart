import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../widgets/booking_progress_indicator.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../widgets/skeleton_loader.dart';
import '../../models/staff_client_model.dart';
import '../barber_create_booking_controller.dart';

/// Step 1 of the barber create-booking wizard: find the client this
/// booking is for, by name or phone, or register a new one on the spot.
class CustomerPage extends GetView<BarberCreateBookingController> {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who is this booking for?')),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            BookingProgressIndicator(
              currentStep: BarberBookingStep.customer.index,
              totalSteps: BarberBookingStep.values.length,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: TextField(
                controller: controller.clientSearchController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Search by name or phone',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: controller.onClientQueryChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Obx(() {
                final query = controller.clientQuery.value.trim();

                if (query.length < 2) {
                  return const EmptyState(
                    icon: Icons.person_search,
                    title: 'Find a client',
                    subtitle: 'Type at least 2 characters of their name or phone number.',
                  );
                }

                if (controller.clientSearchLoading.value) {
                  return const SkeletonList(count: 4, itemHeight: 64);
                }

                if (controller.clientSearchError.value != null) {
                  return EmptyState(
                    icon: Icons.cloud_off,
                    title: "Couldn't search clients",
                    subtitle: controller.clientSearchError.value!,
                    actionLabel: 'Retry',
                    onAction:
                        () => controller.onClientQueryChanged(
                          controller.clientSearchController.text,
                        ),
                  );
                }

                final results = controller.clientResults;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          "No clients found. Register a new one below.",
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      for (final client in results)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm,
                          ),
                          child: _ClientTile(
                            client: client,
                            onTap: () => controller.selectClient(client),
                          ),
                        ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    const _NewClientForm(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final StaffClientModel client;
  final VoidCallback onTap;

  const _ClientTile({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                    Text(client.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${client.phone} · ${client.visitsLabel}',
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

class _NewClientForm extends GetView<BarberCreateBookingController> {
  const _NewClientForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New client', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm + 4),
        TextField(
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => controller.newClientName.value = v,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          decoration: const InputDecoration(labelText: 'Phone number'),
          keyboardType: TextInputType.phone,
          onChanged: (v) => controller.newClientPhone.value = v,
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(
          () => PrimaryButton(
            label: 'Register and continue',
            busy: controller.newClientSubmitting.value,
            onPressed: controller.submitNewClient,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Obx(() {
          if (controller.newClientError.value == null) {
            return const SizedBox.shrink();
          }
          return Text(
            controller.newClientError.value!,
            style: const TextStyle(color: AppColors.late),
          );
        }),
      ],
    );
  }
}
