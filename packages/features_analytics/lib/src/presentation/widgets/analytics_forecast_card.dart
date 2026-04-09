import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/smart_insights.dart' show Forecast;

/// Карточка прогноза
class AnalyticsForecastCard extends ConsumerWidget {
  const AnalyticsForecastCard({super.key, required this.forecast});

  final Forecast forecast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
        locale: context.locale.toLanguageTag(), symbol: currencyCode);

    return Card(
      color: Colors.indigo.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: Colors.indigo.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Прогноз на конец периода',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ForecastItem(
                    label: 'Расходы',
                    value: formatter.format(forecast.projectedExpenses),
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _ForecastItem(
                    label: 'Доходы',
                    value: formatter.format(forecast.projectedIncome),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: forecast.confidence,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(Colors.indigo.shade400),
            ),
            const SizedBox(height: 4),
            Text(
              'Точность: ${(forecast.confidence * 100).toStringAsFixed(0)}% • Осталось ${forecast.daysRemaining} дн.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastItem extends StatelessWidget {
  const _ForecastItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

