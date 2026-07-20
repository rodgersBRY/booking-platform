import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A single bottom-nav destination: an outline/filled icon pair and a
/// label.
class AppBottomNavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppBottomNavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Shared bottom navigation bar — navy bar, brass active color, pill tap
/// targets. Used by both the customer shell and the barber shell so the
/// two workspaces read as one app rather than forking the design system.
class AppBottomNavBar extends StatelessWidget {
  final List<AppBottomNavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Unread-style counter badge per tab, aligned by index with [tabs].
  /// Null (the default) or a shorter list means no badge for that tab —
  /// the customer shell doesn't pass this at all, only the barber shell's
  /// Notifications tab does (per Slice 6 of
  /// docs/superpowers/specs/2026-07-18-barber-workspace-design.md).
  final List<int>? badgeCounts;

  const AppBottomNavBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.badgeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _NavButton(
                tab: tabs[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
                badgeCount:
                    (badgeCounts != null && i < badgeCounts!.length)
                    ? badgeCounts![i]
                    : 0,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final AppBottomNavTab tab;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavButton({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brassLight : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? tab.activeIcon : tab.icon,
                  color: color,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: _Badge(count: badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small red counter pill drawn over a nav icon — caps the printed number
/// at "9+" so it never outgrows the badge.
class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: AppColors.late,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.navy, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
