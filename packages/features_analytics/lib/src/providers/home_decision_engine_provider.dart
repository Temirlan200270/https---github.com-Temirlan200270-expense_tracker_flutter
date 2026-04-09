import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_currency/features_currency.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../behavior_engine/behavior_engine.dart';
import 'analytics_models.dart';
import 'smart_insights.dart';

enum HomeInsightVariant {
  /// Общий перерасход по скорости (ratio ≥ 1.3).
  overallOverspend,

  /// Fallback: одна категория заметно выше нормы (мягче порог).
  categoryFocus,
}

class HomeBehaviorInsight {
  HomeBehaviorInsight({
    required this.variant,
    required this.baseline,
    required this.deviation,
    required this.confidence,
    this.topContributor,
  });

  final HomeInsightVariant variant;
  final TimeWeightedSpendingBaseline baseline;
  final SpendingDeviationResult deviation;
  final InsightConfidenceTier confidence;

  /// Главный «виновник» лишних трат сегодня (вклад к норме).
  final CategoryContribution? topContributor;
}

enum HomeFinancialStateTier {
  stable,
  caution,
  danger,
}

class HomeDecisionSnapshot {
  HomeDecisionSnapshot({
    required this.stateTier,
    required this.monthStats,
    this.behaviorInsight,
    this.forecast,
    this.runwayDays,
  });

  final HomeFinancialStateTier stateTier;
  final AnalyticsStats monthStats;
  final HomeBehaviorInsight? behaviorInsight;
  final Forecast? forecast;
  final int? runwayDays;
}

/// Статус: баланс + прогноз + скорость трат (предиктивно).
HomeFinancialStateTier resolveHomeFinancialState({
  required AnalyticsStats stats,
  required Forecast? forecast,
  required double? overallVelocityRatio,
}) {
  if (stats.balance < 0) {
    return HomeFinancialStateTier.danger;
  }
  if (forecast != null && forecast.projectedBalance < 0) {
    return HomeFinancialStateTier.danger;
  }

  var tier = HomeFinancialStateTier.stable;

  if (stats.totalIncome > 0) {
    final spendRatio = stats.totalExpenses / stats.totalIncome;
    if (spendRatio > 0.88) {
      tier = HomeFinancialStateTier.caution;
    }
  }

  if (overallVelocityRatio != null) {
    if (overallVelocityRatio > 1.3) {
      tier = HomeFinancialStateTier.caution;
      if (forecast != null &&
          forecast.projectedExpenses > forecast.projectedIncome) {
        tier = HomeFinancialStateTier.danger;
      }
    } else if (overallVelocityRatio > 1.1 &&
        tier == HomeFinancialStateTier.stable) {
      tier = HomeFinancialStateTier.caution;
    }
  }

  if (forecast != null &&
      forecast.projectedBalance >= 0 &&
      stats.balance > 0 &&
      forecast.projectedBalance < stats.balance * 0.35) {
    if (tier == HomeFinancialStateTier.stable) {
      tier = HomeFinancialStateTier.caution;
    }
  }

  return tier;
}

int? _monthRunwayDays({
  required double monthBalance,
  required double monthExpenses,
  required int dayOfMonth,
}) {
  if (dayOfMonth < 1 || monthExpenses <= 0) return null;
  final daily = monthExpenses / dayOfMonth;
  if (daily < 0.01) return null;
  if (monthBalance <= 0) return null;
  final days = (monthBalance / daily).floor();
  if (days < 1) return null;
  if (days > 366) return 366;
  return days;
}

final homeDecisionEngineProvider =
    FutureProvider.autoDispose<HomeDecisionSnapshot>((ref) async {
  final all = await ref.watch(expensesStreamProvider.future);
  final categories = await ref.watch(categoriesStreamProvider.future);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1);
  final lastDay = DateTime(now.year, now.month + 1, 0);
  final to = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);

  final monthExpenses = all.where((e) {
    if (e.occurredAt.isBefore(from)) return false;
    if (e.occurredAt.isAfter(to)) return false;
    return true;
  }).toList();

  final monthStats = await AnalyticsStats.fromExpenses(
    monthExpenses,
    defaultCurrency,
    currencyService,
  );

  final forecast = await SmartInsightsService.createForecast(
    expenses: monthExpenses,
    targetCurrency: defaultCurrency,
    currencyService: currencyService,
    periodStart: from,
    periodEnd: to,
  );

  final overallBaseline = await ExpectedSpendingCalculator.computeOverall(
    now: now,
    allExpenses: all,
    targetCurrency: defaultCurrency,
    currencyService: currencyService,
  );
  final overallRatio =
      SpendingVelocityAnalyzer.velocityRatio(overallBaseline);
  final overallDev = overallBaseline != null
      ? SpendingDeviationDetector.detect(
          baseline: overallBaseline,
          velocityRatio: overallRatio,
        )
      : const SpendingDeviationResult.none();

  final stateTier = resolveHomeFinancialState(
    stats: monthStats,
    forecast: forecast,
    overallVelocityRatio: overallRatio,
  );

  final topContributor =
      await CategoryContributionAnalyzer.findTopPositiveContributor(
    now: now,
    allExpenses: all,
    categories: categories,
    targetCurrency: defaultCurrency,
    currencyService: currencyService,
  );

  HomeBehaviorInsight? insight;

  if (overallDev.kind == SpendingDeviationKind.overspending &&
      overallBaseline != null) {
    insight = HomeBehaviorInsight(
      variant: HomeInsightVariant.overallOverspend,
      baseline: overallBaseline,
      deviation: overallDev,
      confidence: InsightConfidenceScorer.forBaseline(overallBaseline),
      topContributor: topContributor,
    );
  } else {
    final fallback =
        await CategoryContributionAnalyzer.findStrongestCategoryOverspend(
      now: now,
      allExpenses: all,
      categories: categories,
      targetCurrency: defaultCurrency,
      currencyService: currencyService,
    );

    if (fallback != null) {
      final fbBaseline = await ExpectedSpendingCalculator.computeForCategory(
        now: now,
        allExpenses: all,
        categoryId: fallback.categoryId,
        targetCurrency: defaultCurrency,
        currencyService: currencyService,
      );
      if (fbBaseline != null) {
        final fr = SpendingVelocityAnalyzer.velocityRatio(fbBaseline);
        final fd = SpendingDeviationDetector.detect(
          baseline: fbBaseline,
          velocityRatio: fr,
        );
        insight = HomeBehaviorInsight(
          variant: HomeInsightVariant.categoryFocus,
          baseline: fbBaseline,
          deviation: fd,
          confidence: InsightConfidenceScorer.forBaseline(fbBaseline),
          topContributor: fallback,
        );
      }
    }

    if (insight == null) {
      final foodId = BehaviorEngineCatalog.pickFoodCategoryId(categories);
      if (foodId != null) {
        final foodBaseline = await ExpectedSpendingCalculator.computeForCategory(
          now: now,
          allExpenses: all,
          categoryId: foodId,
          targetCurrency: defaultCurrency,
          currencyService: currencyService,
        );
        final foodRatio =
            SpendingVelocityAnalyzer.velocityRatio(foodBaseline);
        if (foodBaseline != null) {
          final foodDev = SpendingDeviationDetector.detect(
            baseline: foodBaseline,
            velocityRatio: foodRatio,
          );
          if (foodDev.kind == SpendingDeviationKind.overspending) {
            final match =
                categories.where((c) => c.id == foodId).toList();
            final foodName =
                match.isEmpty ? null : match.first.name;
            insight = HomeBehaviorInsight(
              variant: HomeInsightVariant.categoryFocus,
              baseline: foodBaseline,
              deviation: foodDev,
              confidence: InsightConfidenceScorer.forBaseline(foodBaseline),
              topContributor: CategoryContribution(
                categoryId: foodId,
                categoryName: foodName ?? foodId,
                contribution: foodBaseline.spentTodayUntilNow -
                    foodBaseline.expectedUntilNow,
                actualTodayUntilNow: foodBaseline.spentTodayUntilNow,
                expectedUntilNow: foodBaseline.expectedUntilNow,
                baselineDayCount: foodBaseline.baselineDayCount,
              ),
            );
          }
        }
      }
    }
  }

  final runwayDays = _monthRunwayDays(
    monthBalance: monthStats.balance,
    monthExpenses: monthStats.totalExpenses,
    dayOfMonth: now.day,
  );

  return HomeDecisionSnapshot(
    stateTier: stateTier,
    monthStats: monthStats,
    behaviorInsight: insight,
    forecast: forecast,
    runwayDays: runwayDays,
  );
});
