import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/smart_insights.dart' show SpendingPattern;

/// Карточка паттернов трат
class AnalyticsPatternsCard extends ConsumerWidget {
  const AnalyticsPatternsCard({super.key, required this.patterns});

  final SpendingPattern patterns;

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
                const Icon(Icons.psychology, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Паттерны трат',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PatternRow(
              icon: Icons.arrow_upward,
              iconColor: Colors.red,
              label: 'Больше всего тратите в',
              value: patterns.topSpendingDay,
              subValue: formatter.format(patterns.topSpendingDayAmount),
            ),
            const Divider(),
            _PatternRow(
              icon: Icons.arrow_downward,
              iconColor: Colors.green,
              label: 'Меньше всего тратите в',
              value: patterns.leastSpendingDay,
              subValue: formatter.format(patterns.leastSpendingDayAmount),
            ),
            const Divider(),
            _PatternRow(
              icon: patterns.weekendVsWeekday > 1 ? Icons.weekend : Icons.work,
              iconColor: Colors.blue,
              label: patterns.weekendVsWeekday > 1.2
                  ? 'В выходные тратите больше'
                  : patterns.weekendVsWeekday < 0.8
                      ? 'В будни тратите больше'
                      : 'Траты равномерны',
              value: 'x${patterns.weekendVsWeekday.toStringAsFixed(1)}',
              subValue: null,
            ),
            const Divider(),
            _PatternRow(
              icon: Icons.receipt,
              iconColor: Colors.purple,
              label: 'Средний чек',
              value: formatter.format(patterns.averageTransaction),
              subValue: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subValue,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

