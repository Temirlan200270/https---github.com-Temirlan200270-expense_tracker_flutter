import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_core/data_core.dart';
import 'package:local_db/local_db.dart';
import 'package:shared_models/shared_models.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_expenses/features_expenses.dart';

/// Провайдер репозитория бюджетов
final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalBudgetsRepository(db);
});

/// Провайдер потока бюджетов
final budgetsStreamProvider = StreamProvider.autoDispose<List<Budget>>((ref) {
  final repo = ref.watch(budgetsRepositoryProvider);
  return repo.watchBudgets();
});

/// Провайдер бюджетов с информацией о тратах
final budgetsWithSpendingProvider =
    FutureProvider.autoDispose<List<BudgetWithSpending>>((ref) async {
  final budgetsRepo = ref.watch(budgetsRepositoryProvider);
  final expenses = await ref.watch(expensesStreamProvider.future);
  final categories = await ref.watch(categoriesStreamProvider.future);

  final budgets = await budgetsRepo.fetchBudgets();

  // Создаём карту категорий для названий
  final categoryMap = {for (var c in categories) c.id: c.name};

  return budgets.map((budget) {
    final periodDates = budget.period.getCurrentPeriodDates();

    // Фильтруем расходы по периоду и категории
    final periodExpenses = expenses.where((expense) {
      if (expense.type != ExpenseType.expense) return false;

      final inPeriod = !expense.occurredAt.isBefore(periodDates.start) &&
          !expense.occurredAt.isAfter(periodDates.end);
      if (!inPeriod) return false;

      if (budget.categoryId != null) {
        return expense.categoryId == budget.categoryId;
      }

      return true;
    });

    final spentInCents = periodExpenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amount.amountInCents,
    );

    return BudgetWithSpending(
      budget: budget,
      spentInCents: spentInCents,
      categoryName: budget.categoryId != null 
          ? categoryMap[budget.categoryId] 
          : null,
    );
  }).toList();
});

/// Провайдер бюджетов с предупреждениями (для уведомлений)
final warningBudgetsProvider =
    FutureProvider.autoDispose<List<BudgetWithSpending>>((ref) async {
  final budgetsWithSpending = await ref.watch(budgetsWithSpendingProvider.future);
  return budgetsWithSpending
      .where((b) => b.isWarning && b.budget.notificationsEnabled)
      .toList();
});

/// Провайдер для общего процента использования всех бюджетов
final overallBudgetProgressProvider = FutureProvider.autoDispose<double>((ref) async {
  final budgetsWithSpending = await ref.watch(budgetsWithSpendingProvider.future);
  if (budgetsWithSpending.isEmpty) return 0.0;

  final totalLimit = budgetsWithSpending.fold<int>(
    0,
    (sum, b) => sum + b.budget.limit.amountInCents,
  );
  final totalSpent = budgetsWithSpending.fold<int>(
    0,
    (sum, b) => sum + b.spentInCents,
  );

  if (totalLimit == 0) return 0.0;
  return (totalSpent / totalLimit).clamp(0.0, 2.0);
});

/// Контроллер для управления бюджетами
class BudgetsController extends StateNotifier<AsyncValue<void>> {
  BudgetsController(this._repository) : super(const AsyncValue.data(null));

  final BudgetsRepository _repository;

  /// Создать новый бюджет
  Future<void> createBudget({
    required String name,
    required int limitInCents,
    required String currencyCode,
    required BudgetPeriod period,
    String? categoryId,
    int warningPercent = 80,
    bool notificationsEnabled = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final budget = Budget(
        name: name,
        limit: Money(amountInCents: limitInCents, currencyCode: currencyCode),
        period: period,
        categoryId: categoryId,
        warningPercent: warningPercent,
        notificationsEnabled: notificationsEnabled,
      );
      await _repository.upsertBudget(budget);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Обновить бюджет
  Future<void> updateBudget(Budget budget) async {
    state = const AsyncValue.loading();
    try {
      await _repository.upsertBudget(
        budget.copyWith(updatedAt: DateTime.now().toUtc()),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Удалить бюджет
  Future<void> deleteBudget(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.softDelete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Провайдер контроллера бюджетов
final budgetsControllerProvider =
    StateNotifierProvider.autoDispose<BudgetsController, AsyncValue<void>>(
        (ref) {
  final repo = ref.watch(budgetsRepositoryProvider);
  return BudgetsController(repo);
});

