import 'package:data_core/data_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  throw UnimplementedError('Подмените expensesRepositoryProvider в пакете app');
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  throw UnimplementedError('Подмените categoriesRepositoryProvider в пакете app');
});

final expenseFilterProvider = StateProvider<ExpenseFilter>((ref) {
  return const ExpenseFilter();
});

final expensesStreamProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final repo = ref.watch(expensesRepositoryProvider);
  final filter = ref.watch(expenseFilterProvider);
  return repo.watchExpenses(filter: filter);
});

final categoriesStreamProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.watchAll();
});

final recurringExpensesRepositoryProvider = Provider<RecurringExpensesRepository>((ref) {
  throw UnimplementedError('Подмените recurringExpensesRepositoryProvider в пакете app');
});

final recurringExpensesStreamProvider = StreamProvider.autoDispose<List<RecurringExpense>>((ref) {
  final repo = ref.watch(recurringExpensesRepositoryProvider);
  return repo.watchAll();
});

