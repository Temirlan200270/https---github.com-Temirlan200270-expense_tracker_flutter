import 'home_financial_state_tier.dart';

/// Пороги скорости трат с гистерезисом (SSS Behavior Contract: Stable Truth Layer).
///
/// Вверх и вниз — разные границы, чтобы убрать мерцание CAUTION/DANGER около одного ratio.
abstract final class VelocityThresholds {
  VelocityThresholds._();

  /// Ухудшение: stable → caution.
  static const double stableToCaution = 1.15;

  /// Ухудшение: caution → danger (и stable → danger при скачке).
  static const double cautionToDanger = 1.30;

  /// Улучшение: danger → caution (ниже порога «входа» в danger).
  static const double dangerToCaution = 1.25;

  /// Улучшение: caution → stable.
  static const double cautionToSafe = 1.10;
}

/// Следующий tier **только по скорости трат**, с учётом предыдущего состояния.
///
/// [previousTier] — последний опубликованный tier на Home (память между пересчётами).
/// При отсутствии velocity-сигнала tier по скорости не меняем (возвращаем [previousTier] или stable).
HomeFinancialStateTier nextVelocityTierFromHysteresis({
  required double? velocityRatio,
  required HomeFinancialStateTier? previousTier,
}) {
  final v = velocityRatio;
  if (v == null) {
    return previousTier ?? HomeFinancialStateTier.stable;
  }

  final prev = previousTier ?? HomeFinancialStateTier.stable;

  switch (prev) {
    case HomeFinancialStateTier.stable:
      if (v >= VelocityThresholds.cautionToDanger) {
        return HomeFinancialStateTier.danger;
      }
      if (v >= VelocityThresholds.stableToCaution) {
        return HomeFinancialStateTier.caution;
      }
      return HomeFinancialStateTier.stable;

    case HomeFinancialStateTier.caution:
      if (v >= VelocityThresholds.cautionToDanger) {
        return HomeFinancialStateTier.danger;
      }
      if (v < VelocityThresholds.cautionToSafe) {
        return HomeFinancialStateTier.stable;
      }
      return HomeFinancialStateTier.caution;

    case HomeFinancialStateTier.danger:
      if (v < VelocityThresholds.dangerToCaution) {
        if (v < VelocityThresholds.cautionToSafe) {
          return HomeFinancialStateTier.stable;
        }
        return HomeFinancialStateTier.caution;
      }
      return HomeFinancialStateTier.danger;
  }
}
