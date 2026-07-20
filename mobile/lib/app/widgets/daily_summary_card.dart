import 'package:flutter/material.dart';

import '../modules/barber/models/day_summary_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Today's appointment counts plus working hours, per BARBER-APP.md's
/// "Today's Summary" section.
class DailySummaryCard extends StatelessWidget {
  final DaySummaryModel summary;
  final String? workingHoursLabel;

  const DailySummaryCard({
    super.key,
    required this.summary,
    this.workingHoursLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: "Today's Appointments",
                  value: '${summary.total}',
                ),
              ),
              Expanded(
                child: _Stat(label: 'Completed', value: '${summary.completed}'),
              ),
              Expanded(
                child: _Stat(label: 'Remaining', value: '${summary.remaining}'),
              ),
            ],
          ),
          if (workingHoursLabel != null) ...[
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.brass),
                const SizedBox(width: AppSpacing.xs + 2),
                Text('Working Hours', style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(workingHoursLabel!, style: theme.textTheme.titleMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.displaySmall),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
