import 'dart:async';

import 'package:data_core/data_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../providers/expenses_providers.dart';

final expensesListControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExpensesListController, List<Expense>>(ExpensesListController.new);

class ExpensesListController extends AutoDisposeAsyncNotifier<List<Expense>> {
  @override
  FutureOr<List<Expense>> build() {
    return _load();
  }

  Future<List<Expense>> _load() async {
    final repo = ref.read(expensesRepositoryProvider);
    final filter = ref.watch(expenseFilterProvider);
    return repo.fetchExpenses(filter: filter);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void applyFilter(ExpenseFilter filter) {
    ref.read(expenseFilterProvider.notifier).state = filter;
    refresh();
  }
}

