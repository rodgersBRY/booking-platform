import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SelectableCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBF2) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.brass : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
