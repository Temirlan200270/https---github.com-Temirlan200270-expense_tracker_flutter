import 'package:shared_models/shared_models.dart';

import '../errors/data_failure.dart';
import '../usecases/expense_filters.dart';

abstract class ExpensesRepository {
  Stream<List<Expense>> watchExpenses({ExpenseFilter filter = const ExpenseFilter()});

  Future<List<Expense>> fetchExpenses({ExpenseFilter filter = const ExpenseFilter()});

  Future<Expense> getExpense(String id);

  Future<void> upsertExpense(Expense expense);

  Future<void> softDelete(String id, {DateTime? deletedAt});

  Future<void> softDeleteMany(List<String> ids, {DateTime? deletedAt});

  Future<void> deleteAllExpenses();
}

typedef ExpenseResult<T> = ({T data, DataFailure? failure});

