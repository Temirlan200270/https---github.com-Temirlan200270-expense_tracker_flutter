import 'package:shared_models/shared_models.dart';

/// Репозиторий для повторяющихся транзакций
abstract class RecurringExpensesRepository {
  /// Получить все активные повторяющиеся транзакции
  Future<List<RecurringExpense>> fetchAll({bool includeInactive = false});

  /// Получить повторяющуюся транзакцию по ID
  Future<RecurringExpense?> getRecurringExpense(String id);

  /// Получить все повторяющиеся транзакции, которые нужно обработать
  Future<List<RecurringExpense>> fetchDueRecurringExpenses();

  /// Создать или обновить повторяющуюся транзакцию
  Future<void> upsert(RecurringExpense recurringExpense);

  /// Мягкое удаление повторяющейся транзакции
  Future<void> softDelete(String id, {DateTime? deletedAt});

  /// Поток всех повторяющихся транзакций
  Stream<List<RecurringExpense>> watchAll({bool includeInactive = false});
}

