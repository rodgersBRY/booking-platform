import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/selectable_card.dart';
import '../booking_controller.dart';

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

class StaffListPage extends GetView<BookingController> {
  const StaffListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who would you like?')),
      body: Obx(() {
        if (controller.staffLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.staffError.value != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.staffError.value!, style: const TextStyle(color: AppColors.late)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: controller.loadStaffForSelectedService,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (controller.staff.isEmpty) {
          return const Center(
            child: Text(
              'No staff available for this service right now.',
              style: TextStyle(color: Colors.black45),
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
                  selected: controller.selectedStaffId.value == anyStaffId,
                  onTap: () => controller.selectStaff(anyStaffId),
                  child: _StaffTile(
                    name: _capitalize(controller.anyStaffLabel),
                    subtitle: "We'll pick whoever is free",
                    avatarUrl: null,
                    isAny: true,
                  ),
                ),
              ),
            ),
            ...controller.staff.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Obx(
                  () => SelectableCard(
                    selected: controller.selectedStaffId.value == member.id,
                    onTap: () => controller.selectStaff(member.id),
                    child: _StaffTile(
                      name: member.name,
                      subtitle: _capitalize(member.role),
                      avatarUrl: member.avatarUrl,
                    ),
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
  final String? avatarUrl;
  final bool isAny;

  const _StaffTile({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    this.isAny = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.navy,
          foregroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl != null
              ? null
              : isAny
                  ? const Icon(Icons.people_outline, color: Colors.white, size: 20)
                  : Text(
                      _initials(name),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ),
      ],
    );
  }
}
