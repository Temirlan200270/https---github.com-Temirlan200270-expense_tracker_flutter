import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

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

InsightChipTone _chipToneForUx(UxFinancialTone tone) {
  return switch (tone) {
    UxFinancialTone.risk => InsightChipTone.negative,
    UxFinancialTone.watch => InsightChipTone.caution,
    UxFinancialTone.safe => InsightChipTone.informational,
  };
}

Widget _snapshotLoadingBlock(BuildContext context) {
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
}

/// Блок «единой правды»: [FinancialSnapshot] + те же строки инсайта, что на главной.
class AnalyticsFinancialSnapshotSection extends ConsumerWidget {
  const AnalyticsFinancialSnapshotSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapAsync = ref.watch(financialSnapshotProvider);
    final budgetsAsync = ref.watch(budgetsWithSpendingProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    if (expensesAsync.isLoading && !expensesAsync.hasValue) {
      return _snapshotLoadingBlock(context);
    }

    final emptyLedger =
        expensesAsync.hasValue && (expensesAsync.value?.isEmpty ?? false);
    if (emptyLedger) {
      final cs = Theme.of(context).colorScheme;
      final theme = Theme.of(context);
      final gradient = walletHeroGradientForTone(cs, UxFinancialTone.safe);
      return DecisionGradientShell(
        gradientColors: gradient,
        child: Padding(
          padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('analytics.snapshot.title'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: AnalyticsLayoutSpacing.s12),
              Text(
                tr('analytics.snapshot.ftue_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AnalyticsLayoutSpacing.s8),
              Text(
                tr('analytics.snapshot.ftue_message'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AnalyticsLayoutSpacing.s16),
              Text(
                '${tr('analytics.balance')}: ${formatter.format(0)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AnalyticsLayoutSpacing.s12),
              Center(
                child: InsightChip(
                  label: tr('analytics.snapshot.analysis_mode_chip'),
                  icon: Icons.insights_outlined,
                  tone: InsightChipTone.neutral,
                  onGradient: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return snapAsync.when(
      skipLoadingOnReload: true,
      data: (fin) {
        final cs = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        final ux = UxDecisionMapper.mapSnapshot(
          fin.decision,
          colorScheme: cs,
          formatter: formatter,
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
          unifiedHeroBudgetPressure: fin.decision.budgetPressure,
        );
        final gradient = walletHeroGradientForTone(cs, ux.tone);

        final mainLine = lines.insightLine;
        final subLine = lines.insightContextLine;
        final hintRaw = lines.actionHint;
        final hintTrimmed = (hintRaw ?? '').trim();
        final balance = fin.decision.monthStats.balance;
        final hasMain = mainLine != null && mainLine.trim().isNotEmpty;
        final fromBudget = lines.budgetProgress != null;
        final String? sourceLabel = fromBudget
            ? (hasMain ? tr('insight.source_budget') : null)
            : (hasMain ? tr('insight.source_behavior') : null);

        return DecisionGradientShell(
          gradientColors: gradient,
          child: Padding(
            padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('analytics.snapshot.title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: AnalyticsLayoutSpacing.s8),
                Text(
                  tr('analytics.snapshot.moment_label'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: AnalyticsLayoutSpacing.s8),
                Text(
                  _snapshotFreshnessLabel(context, fin.computedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: AnalyticsLayoutSpacing.s8),
                Text(
                  tr('analytics.snapshot.subtitle'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.35,
                  ),
                ),
                if (sourceLabel != null) ...[
                  const SizedBox(height: AnalyticsLayoutSpacing.s12),
                  Text(
                    sourceLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.48),
                    ),
                  ),
                ],
                if (hasMain) ...[
                  const SizedBox(height: AnalyticsLayoutSpacing.s16),
                  DecisionInsightBlock(
                    analysisHeading: tr('home.hero.analysis_label'),
                    insightLine: mainLine.trim(),
                    contextLine: subLine,
                    hintLine: hintTrimmed.isNotEmpty ? hintTrimmed : null,
                    leadingIcon: walletHeroLeadingIconForTone(ux.tone),
                    budgetProgress: lines.budgetProgress,
                    bottomSpacing: 0,
                  ),
                ] else if (hintTrimmed.isNotEmpty) ...[
                  const SizedBox(height: AnalyticsLayoutSpacing.s16),
                  Text(
                    hintTrimmed,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: AnalyticsLayoutSpacing.s16),
                Text(
                  '${tr('analytics.balance')}: ${formatter.format(balance)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AnalyticsLayoutSpacing.s12),
                Center(
                  child: InsightChip(
                    label: tr('analytics.snapshot.analysis_mode_chip'),
                    icon: Icons.insights_outlined,
                    tone: _chipToneForUx(ux.tone),
                    onGradient: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _snapshotLoadingBlock(context),
      error: (e, _) => AnalyticsErrorCard(message: e.toString()),
    );
  }
}
