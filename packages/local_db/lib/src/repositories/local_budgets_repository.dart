import 'dart:async';

import 'package:drift/drift.dart';
import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

import '../database/app_database.dart';

/// Локальная реализация репозитория бюджетов
class LocalBudgetsRepository implements BudgetsRepository {
  LocalBudgetsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Budget>> watchBudgets() {
    final query = _db.select(_db.budgetsTable)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<List<Budget>> fetchBudgets() async {
    final query = _db.select(_db.budgetsTable)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<Budget?> getBudget(String id) async {
    final query = _db.select(_db.budgetsTable)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();
    return row != null ? _mapRow(row) : null;
  }

  @override
  Future<Budget?> getBudgetByCategory(String categoryId) async {
    final query = _db.select(_db.budgetsTable)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.isActive.equals(true));

    final row = await query.getSingleOrNull();
    return row != null ? _mapRow(row) : null;
  }

  @override
  Future<void> upsertBudget(Budget budget) async {
    await _db.into(_db.budgetsTable).insertOnConflictUpdate(
          BudgetsTableCompanion(
            id: Value(budget.id),
            name: Value(budget.name),
            limitInCents: Value(budget.limit.amountInCents),
            currencyCode: Value(budget.limit.currencyCode),
            period: Value(budget.period.name),
            categoryId: Value(budget.categoryId),
            isActive: Value(budget.isActive),
            warningPercent: Value(budget.warningPercent),
            notificationsEnabled: Value(budget.notificationsEnabled),
            isDeleted: Value(budget.isDeleted),
            deletedAt: Value(budget.deletedAt),
            createdAt: Value(budget.createdAt),
            updatedAt: Value(budget.updatedAt ?? DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Future<void> softDelete(String id, {DateTime? deletedAt}) async {
    await (_db.update(_db.budgetsTable)..where((tbl) => tbl.id.equals(id)))
        .write(
      BudgetsTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(deletedAt ?? DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<List<BudgetWithSpending>> fetchBudgetsWithSpending(
    List<Expense> expenses,
  ) async {
    final budgets = await fetchBudgets();
    return _calculateSpending(budgets, expenses, {});
  }

  @override
  Stream<List<BudgetWithSpending>> watchBudgetsWithSpending(
    Stream<List<Expense>> expensesStream,
    Future<List<Category>> Function() fetchCategories,
  ) {
    // Комбинируем потоки бюджетов и расходов
    return watchBudgets().asyncMap((budgets) async {
      // Получаем категории для отображения названий
      final categories = await fetchCategories();
      final categoryMap = {for (var c in categories) c.id: c.name};

      // Получаем текущие расходы (нужен отдельный fetch, так как поток асинхронный)
      // В реальном использовании это будет комбинироваться с expensesStream
      return _calculateSpending(budgets, [], categoryMap);
    });
  }

  /// Вычисляет траты по каждому бюджету за текущий период
  List<BudgetWithSpending> _calculateSpending(
    List<Budget> budgets,
    List<Expense> allExpenses,
    Map<String, String> categoryNames,
  ) {
    return budgets.map((budget) {
      final periodDates = budget.period.getCurrentPeriodDates();

      // Фильтруем расходы по периоду бюджета
      final periodExpenses = allExpenses.where((expense) {
        // Только расходы (не доходы)
        if (expense.type != ExpenseType.expense) return false;

        // В пределах периода
        final inPeriod = expense.occurredAt.isAfter(periodDates.start) &&
            expense.occurredAt.isBefore(periodDates.end.add(const Duration(seconds: 1)));
        if (!inPeriod) return false;

        // Если бюджет привязан к категории - фильтруем по ней
        if (budget.categoryId != null) {
          return expense.categoryId == budget.categoryId;
        }

        // Общий бюджет - все расходы
        return true;
      });

      // Суммируем расходы в валюте бюджета
      // TODO: Добавить конвертацию валют
      final spentInCents = periodExpenses.fold<int>(
        0,
        (sum, expense) => sum + expense.amount.amountInCents,
      );

      return BudgetWithSpending(
        budget: budget,
        spentInCents: spentInCents,
        categoryName: budget.categoryId != null
            ? categoryNames[budget.categoryId]
            : null,
      );
    }).toList();
  }

  Budget _mapRow(BudgetRow row) {
    return Budget(
      id: row.id,
      name: row.name,
      limit: Money(
        amountInCents: row.limitInCents,
        currencyCode: row.currencyCode,
      ),
      period: BudgetPeriod.values.firstWhere(
        (p) => p.name == row.period,
        orElse: () => BudgetPeriod.monthly,
      ),
      categoryId: row.categoryId,
      isActive: row.isActive,
      warningPercent: row.warningPercent,
      notificationsEnabled: row.notificationsEnabled,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      isDeleted: row.isDeleted,
    );
  }
}

