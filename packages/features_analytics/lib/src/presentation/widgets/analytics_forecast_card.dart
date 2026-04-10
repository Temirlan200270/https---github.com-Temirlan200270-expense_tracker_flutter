import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/smart_insights.dart' show Forecast;
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Прогноз на конец периода (тексты из l10n, цвета из темы).
class AnalyticsForecastCard extends ConsumerWidget {
  const AnalyticsForecastCard({super.key, required this.forecast});

  final Forecast forecast;

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
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 22),
                const SizedBox(width: AnalyticsLayoutSpacing.s8),
                Expanded(
                  child: Text(
                    tr('analytics.forecast.title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: _ForecastItem(
                    label: tr('analytics.expenses'),
                    value: formatter.format(forecast.projectedExpenses),
                    accentColor: cs.error,
                  ),
                ),
                Expanded(
                  child: _ForecastItem(
                    label: tr('analytics.income'),
                    value: formatter.format(forecast.projectedIncome),
                    accentColor: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: forecast.confidence.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s8),
            Text(
              tr(
                'analytics.forecast.meta',
                namedArgs: {
                  'pct': (forecast.confidence * 100).toStringAsFixed(0),
                  'days': '${forecast.daysRemaining}',
                },
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
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
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
