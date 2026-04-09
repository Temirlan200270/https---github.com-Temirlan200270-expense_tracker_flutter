import 'dart:math' as math;

/// Направление изменения относительно «нормы» по недавним дням.
enum TrendDirection {
  /// Темп трат относительно нормы растёт (недавние дни выше предыдущей недели).
  accelerating,

  /// Темп снижается относительно более раннего окна.
  slowing,

  /// Нет устойчивого сдвига или мало данных.
  stable,
}

/// Ядро адаптивной нормы и тренда (decay + инерция поведения).
class BehaviorEngine {
  BehaviorEngine._();

  /// База затухания по индексу: чем меньше [index], тем «свежее» день (0 — самый недавний).
  static double decayWeight(int index, {double base = 0.85}) {
    return math.pow(base, index).toDouble();
  }

  /// Адаптивная норма: взвешенное среднее с экспоненциальным затуханием к прошлому.
  /// [history] — значения от **самого свежего** дня к более старым (как в baseline-листе калькулятора).
  static double calculateAdaptiveNorm(List<double> history) {
    if (history.isEmpty) return 0;
    var weightedSum = 0.0;
    var totalWeight = 0.0;
    for (var i = 0; i < history.length; i++) {
      final w = decayWeight(i);
      weightedSum += history[i] * w;
      totalWeight += w;
    }
    if (totalWeight <= 0) return 0;
    return weightedSum / totalWeight;
  }

  /// Тренд по дневным метрикам (например ratio факт/норма), индекс 0 — самый недавний день.
  /// Сравнивает среднее за 3 свежих дня со средним за до 7 следующих (как в спецификации SSS vNext).
  static TrendDirection detectTrend(List<double> dailyMetrics) {
    if (dailyMetrics.length < 5) return TrendDirection.stable;

    final recentLen = dailyMetrics.length >= 3 ? 3 : dailyMetrics.length;
    var recentSum = 0.0;
    for (var i = 0; i < recentLen; i++) {
      recentSum += dailyMetrics[i];
    }
    final recent = recentSum / recentLen;

    final olderSlice = dailyMetrics.skip(3).take(7).toList();
    if (olderSlice.isEmpty) return TrendDirection.stable;
    var olderSum = 0.0;
    for (final v in olderSlice) {
      olderSum += v;
    }
    final older = olderSum / olderSlice.length;

    final diff = recent - older;
    if (diff > 0.15) return TrendDirection.accelerating;
    if (diff < -0.15) return TrendDirection.slowing;
    return TrendDirection.stable;
  }
}
