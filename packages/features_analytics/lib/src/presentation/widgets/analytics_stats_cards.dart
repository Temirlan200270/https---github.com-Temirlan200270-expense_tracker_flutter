import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/analytics_models.dart';
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Карточки статистики: доходы, расходы, баланс (Analysis Mode, семантика §5 DESIGN_SYSTEM).
class AnalyticsStatsCards extends ConsumerWidget {
  const AnalyticsStatsCards({super.key, required this.stats});

  final AnalyticsStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

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
                accentColor: cs.primary,
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: AnalyticsLayoutSpacing.s12),
            Expanded(
              child: _AnimatedStatCard(
                title: tr('analytics.expenses'),
                value: stats.totalExpenses,
                formatter: formatter,
                subtitle: stats.expenseCount > 0
                    ? '${stats.expenseCount} ${_pluralize(stats.expenseCount, 'запись', 'записи', 'записей')}'
                    : null,
                accentColor: cs.error,
                icon: Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AnalyticsLayoutSpacing.s12),
        _AnimatedStatCard(
          title: tr('analytics.balance'),
          value: stats.balance,
          formatter: formatter,
          accentColor:
              stats.balance >= 0 ? cs.primary : cs.error,
          icon: stats.balance >= 0
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
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
    required this.accentColor,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final double value;
  final NumberFormat formatter;
  final Color accentColor;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        );

    return AnalyticsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20)
                    .animate()
                    .scale(
                      delay: AppMotion.fast,
                      duration: AppMotion.standard,
                      curve: AppMotion.curve,
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                    )
                    .fadeIn(
                      delay: AppMotion.fast,
                      duration: AppMotion.standard,
                      curve: AppMotion.curve,
                    ),
                const SizedBox(width: AnalyticsLayoutSpacing.s8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                      .animate()
                      .fadeIn(
                        delay: AppMotion.fast,
                        duration: AppMotion.standard,
                        curve: AppMotion.curve,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: AppMotion.screen + AppMotion.standard,
              curve: AppMotion.curve,
              builder: (context, animatedValue, _) {
                return Text(
                  formatter.format(animatedValue),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                );
              },
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AnalyticsLayoutSpacing.s8),
              Text(
                subtitle!,
                style: metaStyle,
              )
                  .animate()
                  .fadeIn(
                    delay: AppMotion.screen,
                    duration: AppMotion.standard,
                    curve: AppMotion.curve,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
