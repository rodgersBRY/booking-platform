import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/selectable_card.dart';
import '../booking_controller.dart';

class StaffListPage extends GetView<BookingController> {
  const StaffListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who would you like?')),
      body: Obx(() {
        if (controller.barbersLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.barbersError.value != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.barbersError.value!, style: const TextStyle(color: AppColors.late)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: controller.loadBarbers, child: const Text('Retry')),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Obx(
              () => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableCard(
                  selected: controller.selectedBarberId.value == anyBarberId,
                  onTap: () => controller.selectBarber(anyBarberId),
                  child: const _StaffTile(
                    name: 'Any barber',
                    subtitle: "We'll pick whoever is free",
                  ),
                ),
              ),
            ),
            ...controller.barbers.map(
              (barber) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Obx(
                  () => SelectableCard(
                    selected: controller.selectedBarberId.value == barber.id,
                    onTap: () => controller.selectBarber(barber.id),
                    child: _StaffTile(name: barber.name, subtitle: 'Barber'),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final String name;
  final String subtitle;

  const _StaffTile({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ],
    );
  }
}
