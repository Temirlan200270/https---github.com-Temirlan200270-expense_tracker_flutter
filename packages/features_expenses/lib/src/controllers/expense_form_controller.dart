import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

import '../providers/expenses_providers.dart';

class ExpenseDraft {
  ExpenseDraft({
    required this.amountInCents,
    required this.currencyCode,
    required this.type,
    required this.occurredAt,
    this.categoryId,
    this.note,
  }) : assert(currencyCode.length == 3, 'Код валюты должен состоять из 3 символов');

  final int amountInCents;
  final String currencyCode;
  final ExpenseType type;
  final DateTime occurredAt;
  final String? categoryId;
  final String? note;

  Expense toExpense({String? id}) {
    return Expense(
      id: id ?? Uuid().v4(),
      amount: Money(amountInCents: amountInCents, currencyCode: currencyCode),
      type: type,
      occurredAt: occurredAt,
      categoryId: categoryId,
      note: note,
    );
  }
}

final expenseFormControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExpenseFormController, void>(() {
  return ExpenseFormController();
});

class ExpenseFormController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(ExpenseDraft draft, {String? expenseId}) async {
    state = const AsyncLoading();
    final repo = ref.read(expensesRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final entity = draft.toExpense(id: expenseId);
      await repo.upsertExpense(entity);
    });
  }
}

