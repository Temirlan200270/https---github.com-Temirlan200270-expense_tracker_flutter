import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/analytics_models.dart';
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Сравнение с предыдущим периодом.
class AnalyticsComparisonCard extends ConsumerWidget {
  const AnalyticsComparisonCard({super.key, required this.comparison});

  final ComparisonStats comparison;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    return AnalyticsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('analytics.comparison.title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s12),
            _ComparisonItem(
              label: tr('analytics.income'),
              change: comparison.incomeChange,
              changePercent: comparison.incomeChangePercent,
              formatter: formatter,
              accentColor: cs.primary,
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s8),
            _ComparisonItem(
              label: tr('analytics.expenses'),
              change: comparison.expensesChange,
              changePercent: comparison.expensesChangePercent,
              formatter: formatter,
              accentColor: cs.error,
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s8),
            _ComparisonItem(
              label: tr('analytics.balance'),
              change: comparison.balanceChange,
              changePercent: comparison.balanceChangePercent,
              formatter: formatter,
              accentColor: comparison.balanceChange >= 0 ? cs.primary : cs.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  const _ComparisonItem({
    required this.label,
    required this.change,
    required this.changePercent,
    required this.formatter,
    required this.accentColor,
  });

  final String label;
  final double change;
  final double changePercent;
  final NumberFormat formatter;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Row(
          children: [
            Text(
              '${isPositive ? '+' : ''}${formatter.format(change)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: AnalyticsLayoutSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AnalyticsLayoutSpacing.s8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
