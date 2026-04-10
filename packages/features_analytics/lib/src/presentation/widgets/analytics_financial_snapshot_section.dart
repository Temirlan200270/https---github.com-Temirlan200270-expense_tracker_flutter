import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/home_decision_engine_provider.dart';
import '../layout/analytics_layout_spacing.dart';
import 'analytics_common.dart';
import 'analytics_surface_card.dart';

String _snapshotFreshnessLabel(BuildContext context, DateTime computedAt) {
  final d = DateTime.now().difference(computedAt);
  if (d.inSeconds < 10) {
    return tr('analytics.snapshot.updating_live');
  }
  if (d.inSeconds < 90) {
    return tr('analytics.snapshot.updated_just_now');
  }
  if (d.inMinutes < 60) {
    final n = d.inMinutes.clamp(1, 59).toString();
    return tr(
      'analytics.snapshot.updated_minutes_ago',
      namedArgs: {'n': n},
    );
  }
  final time =
      DateFormat.Hm(context.locale.toLanguageTag()).format(computedAt);
  return tr(
    'analytics.snapshot.updated_at',
    namedArgs: {'time': time},
  );
}

/// Блок «единой правды»: [FinancialSnapshot] + те же строки инсайта, что на главной.
class AnalyticsFinancialSnapshotSection extends ConsumerWidget {
  const AnalyticsFinancialSnapshotSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapAsync = ref.watch(financialSnapshotProvider);
    final budgetsAsync = ref.watch(budgetsWithSpendingProvider);
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    return snapAsync.when(
      data: (fin) {
        final cs = Theme.of(context).colorScheme;
        final narrative = HomeDecisionHeroHelper.build(
          colorScheme: cs,
          snapshot: fin.decision,
          formatter: formatter,
        );
        final ux = UxDecisionMapper.fromHomeNarrative(
          narrative: narrative,
          tier: fin.decision.stateTier,
        );
        final softDep = ref
                .watch(budgetHeroSoftDeprioritizeIdsProvider)
                .valueOrNull ??
            {};
        final rateLimited = ref.watch(budgetHeroRateLimitedIdsProvider);
        final lines = resolveHomeHeroInsight(
          budgetsAsync: budgetsAsync,
          ux: ux,
          formatter: formatter,
          softDeprioritizeBudgetIds: softDep,
          rateLimitedBudgetIds: rateLimited,
        );
        final gradient = walletHeroGradientForTone(cs, ux.tone);
        final accent =
            gradient.length >= 2 ? gradient[1] : cs.primary;

        final mainLine = lines.insightLine;
        final subLine = lines.insightContextLine;
        final hint = lines.actionHint;
        final balance = fin.decision.monthStats.balance;
        final hasMain = mainLine != null && mainLine.trim().isNotEmpty;
        final fromBudget = lines.budgetProgress != null;
        final String? sourceLabel = fromBudget
            ? (hasMain ? tr('insight.source_budget') : null)
            : (hasMain ? tr('insight.source_behavior') : null);

        return AnalyticsSurfaceCard(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [gradient.first, accent],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('analytics.snapshot.title'),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AnalyticsLayoutSpacing.s8),
                        Text(
                          tr('analytics.snapshot.moment_label'),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                        ),
                        const SizedBox(height: AnalyticsLayoutSpacing.s8),
                        Text(
                          _snapshotFreshnessLabel(context, fin.computedAt),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: AnalyticsLayoutSpacing.s8),
                        Text(
                          tr('analytics.snapshot.subtitle'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (sourceLabel != null) ...[
                          const SizedBox(height: AnalyticsLayoutSpacing.s12),
                          Text(
                            sourceLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.45),
                                ),
                          ),
                        ],
                        if (hasMain) ...[
                          const SizedBox(height: AnalyticsLayoutSpacing.s12),
                          Text(
                            mainLine.trim(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                          ),
                        ],
                        if (subLine != null && subLine.trim().isNotEmpty) ...[
                          const SizedBox(height: AnalyticsLayoutSpacing.s8),
                          Text(
                            subLine.trim(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.35,
                                ),
                          ),
                        ],
                        const SizedBox(height: AnalyticsLayoutSpacing.s12),
                        Text(
                          '${tr('analytics.balance')}: ${formatter.format(balance)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (hint != null && hint.trim().isNotEmpty) ...[
                          const SizedBox(height: AnalyticsLayoutSpacing.s8),
                          Text(
                            hint.trim(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        final cs = Theme.of(context).colorScheme;
        return AnalyticsSurfaceCard(
          child: Padding(
            padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s20),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: AnalyticsLayoutSpacing.s12),
                Expanded(
                  child: Text(
                    tr('analytics.snapshot.loading'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (e, _) => AnalyticsErrorCard(message: e.toString()),
    );
  }
}
