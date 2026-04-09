import 'dart:math' as math;

import 'package:features_currency/features_currency.dart';
import 'package:shared_models/shared_models.dart';

// --- Отклонение по скорости трат ---

enum SpendingDeviationKind {
  none,
  overspending,
  underspending,
}

class SpendingDeviationResult {
  const SpendingDeviationResult({
    required this.kind,
    required this.velocityRatio,
    required this.spentTodayUntilNow,
    required this.expectedUntilNow,
  });

  const SpendingDeviationResult.none()
      : kind = SpendingDeviationKind.none,
        velocityRatio = 1,
        spentTodayUntilNow = 0,
        expectedUntilNow = 0;

  final SpendingDeviationKind kind;
  final double velocityRatio;
  final double spentTodayUntilNow;
  final double expectedUntilNow;
}

/// Снимок time-weighted: факт vs ожидание + разброс baseline (для confidence).
class TimeWeightedSpendingBaseline {
  const TimeWeightedSpendingBaseline({
    required this.spentTodayUntilNow,
    required this.expectedUntilNow,
    required this.baselineDayCount,
    required this.usedSameWeekdayOnly,
    this.baselineSampleStdDev,
  });

  final double spentTodayUntilNow;
  final double expectedUntilNow;
  final int baselineDayCount;
  final bool usedSameWeekdayOnly;

  /// Стандартное отклонение дневных «частичных» сумм в baseline (для CV).
  final double? baselineSampleStdDev;
}

/// Уверенность формулировки инсайта (без «рандомных» обещаний).
enum InsightConfidenceTier {
  low,
  medium,
  high,
}

/// Классификация уверенности: объём выборки + коэффициент вариации ожидания.
class InsightConfidenceScorer {
  InsightConfidenceScorer._();

  static InsightConfidenceTier forBaseline(TimeWeightedSpendingBaseline b) {
    final n = b.baselineDayCount;
    if (n < 5) return InsightConfidenceTier.low;
    final mean = b.expectedUntilNow;
    final sd = b.baselineSampleStdDev;
    final cv = (sd != null && mean > 1) ? sd / mean : 0.35;
    if (n >= 14 && cv < 0.55) return InsightConfidenceTier.high;
    if (n >= 8 && cv < 0.75) return InsightConfidenceTier.medium;
    if (n >= 6) return InsightConfidenceTier.medium;
    return InsightConfidenceTier.low;
  }
}

/// Вклад категории в «лишние» траты сегодня к текущему времени.
class CategoryContribution {
  CategoryContribution({
    required this.categoryId,
    required this.categoryName,
    required this.contribution,
    required this.actualTodayUntilNow,
    required this.expectedUntilNow,
    required this.baselineDayCount,
  });

  final String categoryId;
  final String categoryName;

  /// actual - expected (в валюте отчёта).
  final double contribution;
  final double actualTodayUntilNow;
  final double expectedUntilNow;
  final int baselineDayCount;
}

/// Анализ «из-за чего» перерасход: максимальный положительный вклад по категории.
class CategoryContributionAnalyzer {
  CategoryContributionAnalyzer._();

  /// Категория с наибольшим перевыполнением нормы к [now] (только с тратами сегодня).
  static Future<CategoryContribution?> findTopPositiveContributor({
    required DateTime now,
    required List<Expense> allExpenses,
    required List<Category> categories,
    required String targetCurrency,
    required CurrencyService currencyService,
    double? categoryConfidence,
  }) async {
    if (categoryConfidence != null && categoryConfidence < 0.8) {
      return null;
    }

    final todayDate = DateTime(now.year, now.month, now.day);
    final cutoff = now.hour * 60 + now.minute;

    final ids = <String>{};
    for (final e in allExpenses) {
      if (e.isDeleted || !e.type.isExpense || e.categoryId == null) continue;
      final od = e.occurredAt;
      final d = DateTime(od.year, od.month, od.day);
      if (d != todayDate) continue;
      if (od.hour * 60 + od.minute > cutoff) continue;
      ids.add(e.categoryId!);
    }

    final nameMap = {for (final c in categories) c.id: c.name};
    CategoryContribution? best;

    for (final id in ids) {
      final baseline = await ExpectedSpendingCalculator.computeForCategory(
        now: now,
        allExpenses: allExpenses,
        categoryId: id,
        targetCurrency: targetCurrency,
        currencyService: currencyService,
        categoryConfidence: categoryConfidence,
      );
      if (baseline == null) continue;
      final contrib =
          baseline.spentTodayUntilNow - baseline.expectedUntilNow;
      if (contrib <= 0) continue;

      final better = best == null || contrib > best.contribution;
      if (better) {
        best = CategoryContribution(
          categoryId: id,
          categoryName: nameMap[id] ?? id,
          contribution: contrib,
          actualTodayUntilNow: baseline.spentTodayUntilNow,
          expectedUntilNow: baseline.expectedUntilNow,
          baselineDayCount: baseline.baselineDayCount,
        );
      }
    }
    return best;
  }

  /// Лучшая категория по перевыполнению **относительно нормы** (fallback, порог мягче).
  static Future<CategoryContribution?> findStrongestCategoryOverspend({
    required DateTime now,
    required List<Expense> allExpenses,
    required List<Category> categories,
    required String targetCurrency,
    required CurrencyService currencyService,
    double minVelocityRatio = 1.15,
  }) async {
    CategoryContribution? bestByRatio;
    var bestRatio = 0.0;

    final seen = <String>{};
    for (final e in allExpenses) {
      if (e.isDeleted || !e.type.isExpense || e.categoryId == null) continue;
      seen.add(e.categoryId!);
    }

    final nameMap = {for (final c in categories) c.id: c.name};

    for (final id in seen) {
      final baseline = await ExpectedSpendingCalculator.computeForCategory(
        now: now,
        allExpenses: allExpenses,
        categoryId: id,
        targetCurrency: targetCurrency,
        currencyService: currencyService,
      );
      if (baseline == null || baseline.expectedUntilNow <= 0) continue;
      final ratio =
          baseline.spentTodayUntilNow / baseline.expectedUntilNow;
      if (ratio < minVelocityRatio) continue;
      if (ratio > bestRatio) {
        bestRatio = ratio;
        final contrib =
            baseline.spentTodayUntilNow - baseline.expectedUntilNow;
        if (contrib > 0) {
          bestByRatio = CategoryContribution(
            categoryId: id,
            categoryName: nameMap[id] ?? id,
            contribution: contrib,
            actualTodayUntilNow: baseline.spentTodayUntilNow,
            expectedUntilNow: baseline.expectedUntilNow,
            baselineDayCount: baseline.baselineDayCount,
          );
        }
      }
    }
    return bestByRatio;
  }
}

class ExpectedSpendingCalculator {
  ExpectedSpendingCalculator._();

  static const int defaultLookbackDays = 56;
  static const int _minSameWeekdaySamples = 3;
  static const int _minAnyDaySamples = 5;
  static const double _minTimePrecisionFraction = 0.28;

  static Future<TimeWeightedSpendingBaseline?> computeOverall({
    required DateTime now,
    required List<Expense> allExpenses,
    required String targetCurrency,
    required CurrencyService currencyService,
    int lookbackDays = defaultLookbackDays,
  }) async {
    final rates = await currencyService.getExchangeRates();
    double convert(Expense e) => _convertExpense(e, targetCurrency, rates);

    return _baselineUntilNow(
      now: now,
      expenses: allExpenses.where((e) => e.type.isExpense && !e.isDeleted).toList(),
      convert: convert,
      lookbackDays: lookbackDays,
    );
  }

  static Future<TimeWeightedSpendingBaseline?> computeForCategory({
    required DateTime now,
    required List<Expense> allExpenses,
    required String categoryId,
    required String targetCurrency,
    required CurrencyService currencyService,
    double? categoryConfidence,
    int lookbackDays = defaultLookbackDays,
  }) async {
    if (categoryConfidence != null && categoryConfidence < 0.8) {
      return null;
    }

    final rates = await currencyService.getExchangeRates();
    double convert(Expense e) => _convertExpense(e, targetCurrency, rates);

    final list = allExpenses
        .where((e) =>
            e.type.isExpense && !e.isDeleted && e.categoryId == categoryId)
        .toList();

    return _baselineUntilNow(
      now: now,
      expenses: list,
      convert: convert,
      lookbackDays: lookbackDays,
    );
  }

  static double _convertExpense(
    Expense e,
    String targetCurrency,
    Map<String, double> rates,
  ) {
    var amount = e.amount.amount;
    if (e.amount.currencyCode != targetCurrency) {
      final rate = _getRate(e.amount.currencyCode, targetCurrency, rates);
      if (rate != null) amount *= rate;
    }
    return amount;
  }

  static TimeWeightedSpendingBaseline? _baselineUntilNow({
    required DateTime now,
    required List<Expense> expenses,
    required double Function(Expense) convert,
    required int lookbackDays,
  }) {
    if (expenses.isEmpty) return null;

    if (!_hasSufficientTimePrecision(expenses, lookbackDays)) {
      return null;
    }

    final todayDate = DateTime(now.year, now.month, now.day);
    final cutoffMinutes = now.hour * 60 + now.minute;

    final spentToday = _partialDayTotal(
      day: todayDate,
      expenses: expenses,
      cutoffMinutes: cutoffMinutes,
      convert: convert,
    );

    final sameWeekdayValues = <double>[];
    final anyDayValues = <double>[];

    for (var delta = 1; delta <= lookbackDays; delta++) {
      final d = todayDate.subtract(Duration(days: delta));
      final partial = _partialDayTotal(
        day: d,
        expenses: expenses,
        cutoffMinutes: cutoffMinutes,
        convert: convert,
      );
      anyDayValues.add(partial);
      if (d.weekday == now.weekday) {
        sameWeekdayValues.add(partial);
      }
    }

    List<double> baseline;
    var usedSameWeekday = false;
    if (sameWeekdayValues.length >= _minSameWeekdaySamples) {
      baseline = sameWeekdayValues;
      usedSameWeekday = true;
    } else if (anyDayValues.length >= _minAnyDaySamples) {
      baseline = anyDayValues;
    } else {
      return null;
    }

    final expected =
        baseline.reduce((a, b) => a + b) / baseline.length;
    if (expected <= 0) return null;

    final std = _populationStdDev(baseline);

    return TimeWeightedSpendingBaseline(
      spentTodayUntilNow: spentToday,
      expectedUntilNow: expected,
      baselineDayCount: baseline.length,
      usedSameWeekdayOnly: usedSameWeekday,
      baselineSampleStdDev: std,
    );
  }

  static double? _populationStdDev(List<double> values) {
    if (values.length < 2) return null;
    final mean = values.reduce((a, b) => a + b) / values.length;
    var s = 0.0;
    for (final v in values) {
      final d = v - mean;
      s += d * d;
    }
    return math.sqrt(s / values.length);
  }

  static double _partialDayTotal({
    required DateTime day,
    required List<Expense> expenses,
    required int cutoffMinutes,
    required double Function(Expense) convert,
  }) {
    var sum = 0.0;
    for (final e in expenses) {
      final od = e.occurredAt;
      final d = DateTime(od.year, od.month, od.day);
      if (d != day) continue;
      final m = od.hour * 60 + od.minute;
      if (m <= cutoffMinutes) {
        sum += convert(e);
      }
    }
    return sum;
  }

  static bool _hasSufficientTimePrecision(
    List<Expense> expenses,
    int lookbackDays,
  ) {
    final from = DateTime.now().subtract(Duration(days: lookbackDays));
    final recent = expenses
        .where((e) => e.occurredAt.isAfter(from))
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    if (recent.length < 8) return false;

    var withTime = 0;
    final take = recent.length.clamp(0, 48);
    for (var i = 0; i < take; i++) {
      final od = recent[i].occurredAt;
      if (od.hour != 0 || od.minute != 0) withTime++;
    }
    return withTime / take >= _minTimePrecisionFraction;
  }

  static double? _getRate(String from, String to, Map<String, double> rates) {
    if (from == to) return 1.0;
    if (from == 'USD') return rates[to];
    if (to == 'USD') {
      final fromRate = rates[from];
      return fromRate != null ? 1.0 / fromRate : null;
    }
    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate != null && toRate != null) {
      return toRate / fromRate;
    }
    return null;
  }
}

class SpendingVelocityAnalyzer {
  SpendingVelocityAnalyzer._();

  static double? velocityRatio(TimeWeightedSpendingBaseline? baseline) {
    if (baseline == null || baseline.expectedUntilNow <= 0) return null;
    return baseline.spentTodayUntilNow / baseline.expectedUntilNow;
  }
}

class SpendingDeviationDetector {
  SpendingDeviationDetector._();

  static const double overspendThreshold = 1.3;
  static const double underspendThreshold = 0.7;

  static SpendingDeviationResult detect({
    required TimeWeightedSpendingBaseline baseline,
    required double? velocityRatio,
  }) {
    final ratio = velocityRatio;
    if (ratio == null) {
      return const SpendingDeviationResult.none();
    }

    if (ratio > overspendThreshold) {
      return SpendingDeviationResult(
        kind: SpendingDeviationKind.overspending,
        velocityRatio: ratio,
        spentTodayUntilNow: baseline.spentTodayUntilNow,
        expectedUntilNow: baseline.expectedUntilNow,
      );
    }
    if (ratio < underspendThreshold) {
      return SpendingDeviationResult(
        kind: SpendingDeviationKind.underspending,
        velocityRatio: ratio,
        spentTodayUntilNow: baseline.spentTodayUntilNow,
        expectedUntilNow: baseline.expectedUntilNow,
      );
    }

    return SpendingDeviationResult(
      kind: SpendingDeviationKind.none,
      velocityRatio: ratio,
      spentTodayUntilNow: baseline.spentTodayUntilNow,
      expectedUntilNow: baseline.expectedUntilNow,
    );
  }
}

class BehaviorEngineCatalog {
  BehaviorEngineCatalog._();

  static final _foodTokens = {
    'еда',
    'food',
    'продукт',
    'grocery',
    'кафе',
    'ресторан',
    'meal',
    'обед',
    'завтрак',
    'ужин',
    'coffee',
    'кофе',
    'delivery',
    'доставка',
  };

  static String? pickFoodCategoryId(List<Category> categories) {
    for (final c in categories) {
      if (c.isDeleted || !c.kind.isExpense) continue;
      final name = c.name.toLowerCase().trim();
      for (final token in _foodTokens) {
        if (name.contains(token)) return c.id;
      }
    }
    return null;
  }
}
