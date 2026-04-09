import 'package:features_expenses/src/controllers/expense_form_controller.dart';
import 'package:features_expenses/src/providers/expenses_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_db/local_db.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('ExpenseFormController Tests', () {
    late AppDatabase database;
    late LocalExpensesRepository expensesRepo;
    late LocalCategoriesRepository categoriesRepo;

    setUp(() async {
      database = AppDatabase();
      expensesRepo = LocalExpensesRepository(database);
      categoriesRepo = LocalCategoriesRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('создание новой транзакции', () async {
      // Создаём тестовую категорию
      final category = Category(
        name: 'Тестовая категория',
        colorValue: 0xFF4CAF50,
        kind: CategoryKind.expense,
      );
      await categoriesRepo.upsertMany([category]);

      final container = ProviderContainer(
        overrides: [
          expensesRepositoryProvider.overrideWithValue(expensesRepo),
        ],
      );

      final notifier = container.read(expenseFormControllerProvider.notifier);

      final draft = ExpenseDraft(
        amountInCents: 10000,
        currencyCode: 'KZT',
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: category.id,
        note: 'Тестовая заметка',
      );

      await notifier.submit(draft);
      await container.read(expenseFormControllerProvider.future);

      // Проверяем, что транзакция создана
      final expenses = await expensesRepo.fetchExpenses();
      expect(expenses.any((e) => e.amount.amountInCents == 10000), isTrue);
      expect(expenses.any((e) => e.note == 'Тестовая заметка'), isTrue);
    });

    test('редактирование существующей транзакции', () async {
      // Создаём тестовую категорию
      final category = Category(
        name: 'Тестовая категория',
        colorValue: 0xFF4CAF50,
        kind: CategoryKind.expense,
      );
      await categoriesRepo.upsertMany([category]);

      // Создаём исходную транзакцию
      final originalExpense = Expense(
        id: Uuid().v4(),
        amount: Money(amountInCents: 10000, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: category.id,
        note: 'Исходная заметка',
      );
      await expensesRepo.upsertExpense(originalExpense);

      final container = ProviderContainer(
        overrides: [
          expensesRepositoryProvider.overrideWithValue(expensesRepo),
        ],
      );

      final notifier = container.read(expenseFormControllerProvider.notifier);

      // Обновляем транзакцию
      final draft = ExpenseDraft(
        amountInCents: 20000,
        currencyCode: 'KZT',
        type: ExpenseType.expense,
        occurredAt: originalExpense.occurredAt,
        categoryId: category.id,
        note: 'Обновлённая заметка',
      );

      await notifier.submit(draft, expenseId: originalExpense.id);
      await container.read(expenseFormControllerProvider.future);

      // Проверяем, что транзакция обновлена
      final updated = await expensesRepo.getExpense(originalExpense.id);
      expect(updated.amount.amountInCents, 20000);
      expect(updated.note, 'Обновлённая заметка');
      expect(updated.id, originalExpense.id); // ID должен остаться прежним
    });

    test('создание транзакции без категории', () async {
      final container = ProviderContainer(
        overrides: [
          expensesRepositoryProvider.overrideWithValue(expensesRepo),
        ],
      );

      final notifier = container.read(expenseFormControllerProvider.notifier);

      final draft = ExpenseDraft(
        amountInCents: 10000,
        currencyCode: 'KZT',
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: null,
        note: null,
      );

      await notifier.submit(draft);
      await container.read(expenseFormControllerProvider.future);

      // Проверяем, что транзакция создана без категории
      final expenses = await expensesRepo.fetchExpenses();
      expect(expenses.any((e) => e.categoryId == null), isTrue);
    });
  });
}
