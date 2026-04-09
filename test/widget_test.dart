import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  test('ExpenseDraft -> Expense содержит корректные значения', () {
    final draft = Expense(
      id: 'test',
      amount: const Money(amountInCents: 12345, currencyCode: 'RUB'),
      type: ExpenseType.expense,
      occurredAt: DateTime(2024, 10, 1),
      note: 'Coffee',
    );

    expect(draft.amount.amountInCents, 12345);
    expect(draft.amount.currencyCode, 'RUB');
    expect(draft.type.isExpense, true);
  });
}
