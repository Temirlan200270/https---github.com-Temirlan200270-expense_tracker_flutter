import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/home_decision_engine_provider.dart';
import 'analytics_common.dart';

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
        final lines = resolveHomeHeroInsight(
          budgetsAsync: budgetsAsync,
          ux: ux,
          formatter: formatter,
        );
        final gradient = walletHeroGradientForTone(cs, ux.tone);
        final accent =
            gradient.length >= 2 ? gradient[1] : cs.primary;

        final mainLine = lines.insightLine;
        final subLine = lines.insightContextLine;
        final hint = lines.actionHint;
        final balance = fin.decision.monthStats.balance;

        return Card(
          clipBehavior: Clip.antiAlias,
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
                    padding: const EdgeInsets.all(16),
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
                        const SizedBox(height: 4),
                        Text(
                          tr('analytics.snapshot.subtitle'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (mainLine != null && mainLine.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 6),
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
                        const SizedBox(height: 10),
                        Text(
                          '${tr('analytics.balance')}: ${formatter.format(balance)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (hint != null && hint.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
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
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tr('analytics.snapshot.loading'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => AnalyticsErrorCard(message: e.toString()),
    );
  }
}
