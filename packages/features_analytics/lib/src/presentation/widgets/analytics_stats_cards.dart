import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/analytics_models.dart';

/// Карточки статистики (доходы, расходы, баланс)
class AnalyticsStatsCards extends ConsumerWidget {
  const AnalyticsStatsCards({super.key, required this.stats});

  final AnalyticsStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
        locale: context.locale.toLanguageTag(), symbol: currencyCode);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                title: tr('analytics.income'),
                value: stats.totalIncome,
                formatter: formatter,
                subtitle: stats.incomeCount > 0
                    ? '${stats.incomeCount} ${_pluralize(stats.incomeCount, 'запись', 'записи', 'записей')}'
                    : null,
                color: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatCard(
                title: tr('analytics.expenses'),
                value: stats.totalExpenses,
                formatter: formatter,
                subtitle: stats.expenseCount > 0
                    ? '${stats.expenseCount} ${_pluralize(stats.expenseCount, 'запись', 'записи', 'записей')}'
                    : null,
                color: Colors.red,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AnimatedStatCard(
          title: tr('analytics.balance'),
          value: stats.balance,
          formatter: formatter,
          color: stats.balance >= 0 ? Colors.green : Colors.red,
          icon: stats.balance >= 0 ? Icons.check_circle : Icons.warning,
        ),
      ],
    );
  }

  String _pluralize(int count, String one, String few, String many) {
    if (count % 10 == 1 && count % 100 != 11) {
      return one;
    }
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return few;
    }
    return many;
  }
}

class _AnimatedStatCard extends StatelessWidget {
  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.formatter,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final double value;
  final NumberFormat formatter;
  final Color color;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20)
                    .animate()
                    .scale(
                        delay: 100.ms,
                        duration: 400.ms,
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1))
                    .fadeIn(delay: 100.ms, duration: 300.ms),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return Text(
                  formatter.format(animatedValue),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                );
              },
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            ],
          ],
        ),
      ),
    );
  }
}

