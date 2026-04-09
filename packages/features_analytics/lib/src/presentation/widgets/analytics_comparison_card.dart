import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/analytics_models.dart';

/// Карточка сравнения с предыдущим периодом
class AnalyticsComparisonCard extends ConsumerWidget {
  const AnalyticsComparisonCard({super.key, required this.comparison});

  final ComparisonStats comparison;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
        locale: context.locale.toLanguageTag(), symbol: currencyCode);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('analytics.comparison.title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ComparisonItem(
              label: tr('analytics.income'),
              change: comparison.incomeChange,
              changePercent: comparison.incomeChangePercent,
              formatter: formatter,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _ComparisonItem(
              label: tr('analytics.expenses'),
              change: comparison.expensesChange,
              changePercent: comparison.expensesChangePercent,
              formatter: formatter,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            _ComparisonItem(
              label: tr('analytics.balance'),
              change: comparison.balanceChange,
              changePercent: comparison.balanceChangePercent,
              formatter: formatter,
              color: comparison.balanceChange >= 0 ? Colors.green : Colors.red,
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
    required this.color,
  });

  final String label;
  final double change;
  final double changePercent;
  final NumberFormat formatter;
  final Color color;

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
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

