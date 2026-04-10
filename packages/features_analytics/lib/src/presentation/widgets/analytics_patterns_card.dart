import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/smart_insights.dart' show SpendingPattern;
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Паттерны трат (локализованные подписи).
class AnalyticsPatternsCard extends ConsumerWidget {
  const AnalyticsPatternsCard({super.key, required this.patterns});

  final SpendingPattern patterns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
      decimalDigits: 0,
    );

    final weekendLabel = patterns.weekendVsWeekday > 1.2
        ? tr('analytics.patterns.weekend_more')
        : patterns.weekendVsWeekday < 0.8
            ? tr('analytics.patterns.weekday_more')
            : tr('analytics.patterns.balanced');

    return AnalyticsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_rounded, size: 22, color: cs.tertiary),
                const SizedBox(width: AnalyticsLayoutSpacing.s8),
                Text(
                  tr('analytics.patterns.title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s16),
            _PatternRow(
              icon: Icons.arrow_upward_rounded,
              iconColor: cs.error,
              label: tr('analytics.patterns.most_spend'),
              value: patterns.topSpendingDay,
              subValue: formatter.format(patterns.topSpendingDayAmount),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            _PatternRow(
              icon: Icons.arrow_downward_rounded,
              iconColor: cs.primary,
              label: tr('analytics.patterns.least_spend'),
              value: patterns.leastSpendingDay,
              subValue: formatter.format(patterns.leastSpendingDayAmount),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            _PatternRow(
              icon: patterns.weekendVsWeekday > 1
                  ? Icons.weekend_rounded
                  : Icons.work_rounded,
              iconColor: cs.secondary,
              label: weekendLabel,
              value: tr(
                'analytics.patterns.ratio',
                namedArgs: {
                  'x': patterns.weekendVsWeekday.toStringAsFixed(1),
                },
              ),
              subValue: null,
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            _PatternRow(
              icon: Icons.receipt_long_rounded,
              iconColor: cs.tertiary,
              label: tr('analytics.patterns.avg_check'),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AnalyticsLayoutSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AnalyticsLayoutSpacing.s12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
