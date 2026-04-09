import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

/// Сервис для обработки повторяющихся транзакций
class RecurringExpensesService {
  RecurringExpensesService({
    required this.recurringRepo,
    required this.expensesRepo,
  });

  final RecurringExpensesRepository recurringRepo;
  final ExpensesRepository expensesRepo;

  /// Обрабатывает все повторяющиеся транзакции, которые нужно создать
  Future<int> processDueRecurringExpenses() async {
    final due = await recurringRepo.fetchDueRecurringExpenses();
    int generated = 0;

    for (final recurring in due) {
      if (!recurring.shouldGenerateNow()) continue;

      // Создаём транзакцию
      final expense = recurring.generateExpense();
      await expensesRepo.upsertExpense(expense);

      // Обновляем повторяющуюся транзакцию
      final now = DateTime.now();
      final nextOccurrence = recurring.calculateNextOccurrence(now);
      
      await recurringRepo.upsert(
        recurring.copyWith(
          lastGenerated: now,
          nextOccurrence: nextOccurrence,
          updatedAt: now,
        ),
      );

      generated++;
    }

    return generated;
  }

  /// Создаёт транзакцию из повторяющейся вручную
  Future<Expense> generateExpenseManually(RecurringExpense recurring) async {
    final expense = recurring.generateExpense();
    await expensesRepo.upsertExpense(expense);

    // Обновляем nextOccurrence
    final now = DateTime.now();
    final nextOccurrence = recurring.calculateNextOccurrence(now);
    
    await recurringRepo.upsert(
      recurring.copyWith(
        lastGenerated: now,
        nextOccurrence: nextOccurrence,
        updatedAt: now,
      ),
    );

    return expense;
  }
}

