import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/smart_insights.dart' show AverageStats;
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Средние показатели за период.
class AnalyticsAveragesCard extends ConsumerWidget {
  const AnalyticsAveragesCard({super.key, required this.averages});

  final AverageStats averages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
      decimalDigits: 0,
    );

    return AnalyticsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_rounded, size: 22, color: cs.primary),
                const SizedBox(width: AnalyticsLayoutSpacing.s8),
                Text(
                  tr('analytics.averages_title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: _AverageItem(
                    label: tr('analytics.average.daily'),
                    expense: formatter.format(averages.dailyExpense),
                    income: formatter.format(averages.dailyIncome),
                  ),
                ),
                Expanded(
                  child: _AverageItem(
                    label: tr('analytics.average.weekly'),
                    expense: formatter.format(averages.weeklyExpense),
                    income: formatter.format(averages.weeklyIncome),
                  ),
                ),
                Expanded(
                  child: _AverageItem(
                    label: tr('analytics.average.monthly'),
                    expense: formatter.format(averages.monthlyExpense),
                    income: formatter.format(averages.monthlyIncome),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AverageItem extends StatelessWidget {
  const _AverageItem({
    required this.label,
    required this.expense,
    required this.income,
  });

  final String label;
  final String expense;
  final String income;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AnalyticsLayoutSpacing.s8),
        Text(
          expense,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        Text(
          income,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
