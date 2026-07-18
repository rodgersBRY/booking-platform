import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/staff_presence.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Dashboard's prominent status card — current presence with a themed
/// status dot and a "Change Status" action. Large and near the top per
/// BARBER-APP.md's Availability Card section.
class AvailabilityCard extends StatelessWidget {
  final StaffPresence presence;
  final String? presenceUpdatedAt;
  final VoidCallback onChangeStatus;

  /// True while a presence change is in flight — disables the button so
  /// a second tap can't race the first.
  final bool busy;

  const AvailabilityCard({
    super.key,
    required this.presence,
    required this.presenceUpdatedAt,
    required this.onChangeStatus,
    this.busy = false,
  });

  String? get _updatedLabel {
    final raw = presenceUpdatedAt;
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return null;
    return 'Updated ${DateFormat('h:mm a').format(parsed)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: presence.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    presence.label,
                    key: ValueKey(presence),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (_updatedLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(_updatedLabel!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: busy ? null : onChangeStatus,
            child:
                busy
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Change Status'),
          ),
        ],
      ),
    );
  }
}

/// The four presence options as a bottom sheet, per BARBER-APP.md's
/// Availability section. Returns the selected value, or null if dismissed
/// without a selection — the caller (BarberDashboardController) owns the
/// actual API call so this widget stays a dumb picker.
Future<StaffPresence?> showChangeStatusSheet(
  BuildContext context,
  StaffPresence current,
) {
  return showModalBottomSheet<StaffPresence>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Change Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              for (final option in StaffPresence.values)
                ListTile(
                  minVerticalPadding: 14,
                  leading: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(option.label),
                  trailing:
                      option == current
                          ? const Icon(Icons.check, color: AppColors.brass)
                          : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ),
      );
    },
  );
}
