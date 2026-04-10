import 'package:easy_localization/easy_localization.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/analytics_providers.dart';
import '../../providers/analytics_period_provider.dart';
import '../../providers/home_decision_engine_provider.dart';
import '../layout/analytics_layout_spacing.dart';
import '../widgets/analytics_common.dart';
import '../widgets/analytics_period_selector.dart'
    show AnalyticsPeriodSelector, AnalyticsPeriodSelectorSheet;
import '../widgets/analytics_stats_cards.dart';
import '../widgets/analytics_insights_section.dart';
import '../widgets/analytics_forecast_card.dart';
import '../widgets/analytics_averages_card.dart';
import '../widgets/analytics_patterns_card.dart';
import '../widgets/analytics_comparison_card.dart';
import '../widgets/analytics_time_chart.dart';
import '../widgets/analytics_category_chart.dart';
import '../widgets/analytics_financial_snapshot_section.dart';

/// Экран аналитики (Analysis Mode, DESIGN_SYSTEM §2.3 + SSS_UI_SYSTEM_V2).
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  static Widget _sectionSpacing() =>
      const SizedBox(height: AnalyticsLayoutSpacing.sectionGap);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodState = ref.watch(analyticsPeriodProvider);
    final statsAsync = ref.watch(analyticsStatsProvider);
    final categoryStatsAsync = ref.watch(categoryStatsProvider);
    final timeStatsAsync = ref.watch(timeStatsProvider);
    final comparisonAsync = ref.watch(comparisonStatsProvider);
    final insightsAsync = ref.watch(smartInsightsProvider);
    final averagesAsync = ref.watch(averageStatsProvider);
    final patternsAsync = ref.watch(spendingPatternsProvider);
    final forecastAsync = ref.watch(forecastProvider);

    return PrimaryScaffold(
      title: tr('analytics.title'),
      actions: [
        OutlinedCircleIconButton(
          icon: Icons.filter_list_rounded,
          tooltip: tr('analytics.period'),
          onPressed: () => _showPeriodSelector(context, ref),
        ),
      ],
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          await Future.wait([
            ref.refresh(financialSnapshotProvider.future),
            ref.refresh(budgetsWithSpendingProvider.future),
            ref.refresh(analyticsStatsProvider.future),
            ref.refresh(categoryStatsProvider.future),
            ref.refresh(timeStatsProvider.future),
            ref.refresh(comparisonStatsProvider.future),
            ref.refresh(smartInsightsProvider.future),
            ref.refresh(averageStatsProvider.future),
            ref.refresh(spendingPatternsProvider.future),
            ref.refresh(forecastProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AnalyticsLayoutSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedAnalyticsSection(
                index: 0,
                child: const AnalyticsFinancialSnapshotSection(),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 1,
                child: AnalyticsPeriodSelector(periodState: periodState),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 2,
                child: statsAsync.when(
                  data: (stats) => AnalyticsStatsCards(stats: stats),
                  loading: () => const AnalyticsLoadingCard(),
                  error: (error, _) =>
                      AnalyticsErrorCard(message: error.toString()),
                ),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 3,
                child: insightsAsync.when(
                  data: (insights) => insights.isNotEmpty
                      ? AnalyticsInsightsSection(insights: insights)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 4,
                child: forecastAsync.when(
                  data: (forecast) => forecast != null
                      ? AnalyticsForecastCard(forecast: forecast)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 5,
                child: comparisonAsync.when(
                  data: (comparison) {
                    if (comparison == null) {
                      return const SizedBox.shrink();
                    }
                    return AnalyticsComparisonCard(comparison: comparison);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 6,
                child: averagesAsync.when(
                  data: (averages) => averages != null
                      ? AnalyticsAveragesCard(averages: averages)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 7,
                child: patternsAsync.when(
                  data: (patterns) => patterns != null
                      ? AnalyticsPatternsCard(patterns: patterns)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 8,
                child: timeStatsAsync.when(
                  data: (stats) => AnalyticsTimeChart(stats: stats),
                  loading: () => const AnalyticsLoadingCard(),
                  error: (error, _) =>
                      AnalyticsErrorCard(message: error.toString()),
                ),
              ),
              _sectionSpacing(),
              AnimatedAnalyticsSection(
                index: 9,
                child: categoryStatsAsync.when(
                  data: (stats) => AnalyticsCategoryChart(stats: stats),
                  loading: () => const AnalyticsLoadingCard(),
                  error: (error, _) =>
                      AnalyticsErrorCard(message: error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => const AnalyticsPeriodSelectorSheet(),
    );
  }
}
