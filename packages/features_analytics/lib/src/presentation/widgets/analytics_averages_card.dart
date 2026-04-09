import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/smart_insights.dart' show AverageStats;

/// Карточка средних показателей
class AnalyticsAveragesCard extends ConsumerWidget {
  const AnalyticsAveragesCard({super.key, required this.averages});

  final AverageStats averages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Средние показатели',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          expense,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          income,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
              ),
        ),
      ],
    );
  }
}

