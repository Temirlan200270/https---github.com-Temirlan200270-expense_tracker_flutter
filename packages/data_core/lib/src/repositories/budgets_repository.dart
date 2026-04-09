import 'package:shared_models/shared_models.dart';

/// Абстрактный репозиторий для работы с бюджетами
abstract class BudgetsRepository {
  /// Получить поток всех активных бюджетов
  Stream<List<Budget>> watchBudgets();

  /// Получить все активные бюджеты
  Future<List<Budget>> fetchBudgets();

  /// Получить бюджет по ID
  Future<Budget?> getBudget(String id);

  /// Получить бюджет по категории
  Future<Budget?> getBudgetByCategory(String categoryId);

  /// Создать или обновить бюджет
  Future<void> upsertBudget(Budget budget);

  /// Мягкое удаление бюджета
  Future<void> softDelete(String id, {DateTime? deletedAt});

  /// Получить все бюджеты с информацией о тратах за текущий период
  Future<List<BudgetWithSpending>> fetchBudgetsWithSpending(List<Expense> expenses);

  /// Поток бюджетов с информацией о тратах
  Stream<List<BudgetWithSpending>> watchBudgetsWithSpending(
    Stream<List<Expense>> expensesStream,
    Future<List<Category>> Function() fetchCategories,
  );
}

