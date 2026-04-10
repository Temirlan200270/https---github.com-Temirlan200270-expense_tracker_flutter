import 'budget.dart';

/// Агрегированное давление по бюджетам для Decision Engine (только числа и enum, без UI-строк).
class HomeBudgetPressure {
  const HomeBudgetPressure({
    required this.aggregateUtilization,
    required this.worstLineStatus,
    this.primaryBudgetId,
  });

  /// Σ потрачено / Σ лимитов по активным бюджетам (> 1.0 при суммарном перевыполнении).
  final double aggregateUtilization;

  /// Наихудший статус среди линий (превышение важнее предупреждения).
  final BudgetStatus worstLineStatus;

  /// Бюджет с максимальным progress внутри «худшей» группы статусов (для приоритета инсайта).
  final String? primaryBudgetId;

  /// Строит срез по активным неудалённым бюджетам; `null`, если таких нет.
  static HomeBudgetPressure? fromActiveBudgets(List<BudgetWithSpending> rows) {
    final active = rows
        .where((r) => !r.budget.isDeleted && r.budget.isActive)
        .toList();
    if (active.isEmpty) return null;

    final hasExceeded = active.any((r) => r.isOverBudget);
    final hasWarning =
        active.any((r) => r.isWarning && !r.isOverBudget);

    final worst = hasExceeded
        ? BudgetStatus.exceeded
        : (hasWarning ? BudgetStatus.warning : BudgetStatus.normal);

    Iterable<BudgetWithSpending> candidates = active;
    if (worst == BudgetStatus.exceeded) {
      candidates = active.where((r) => r.isOverBudget);
    } else if (worst == BudgetStatus.warning) {
      candidates = active.where((r) => r.isWarning && !r.isOverBudget);
    }

    BudgetWithSpending? pick;
    for (final r in candidates) {
      if (pick == null || r.progress > pick.progress) pick = r;
    }

    final primaryId =
        worst == BudgetStatus.normal ? null : pick?.budget.id;

    var totalLimit = 0;
    var totalSpent = 0;
    for (final r in active) {
      totalLimit += r.budget.limit.amountInCents;
      totalSpent += r.spentInCents;
    }
    final util =
        totalLimit > 0 ? totalSpent / totalLimit : 0.0;

    return HomeBudgetPressure(
      aggregateUtilization: util,
      worstLineStatus: worst,
      primaryBudgetId: primaryId,
    );
  }
}
