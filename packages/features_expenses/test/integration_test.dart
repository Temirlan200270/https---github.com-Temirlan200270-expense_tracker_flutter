import 'package:easy_localization/easy_localization.dart';
import 'package:features_expenses/src/presentation/pages/new_expense_page.dart';
import 'package:features_expenses/src/providers/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_db/local_db.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Интеграционные тесты: добавить → увидеть → график', () {
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

    testWidgets('полный поток: добавление расхода и отображение в списке',
        (WidgetTester tester) async {
      // Создаём тестовую категорию
      final category = Category(
        name: 'Тестовая категория',
        colorValue: 0xFF4CAF50,
        kind: CategoryKind.expense,
      );
      await categoriesRepo.upsertMany([category]);

      // Создаём тестовый расход
      final expense = Expense(
        id: Uuid().v4(),
        amount: Money(amountInCents: 10000, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: category.id,
        note: 'Тестовый расход',
      );

      await expensesRepo.upsertExpense(expense);

      // Проверяем, что расход сохранён
      final savedExpense = await expensesRepo.getExpense(expense.id);
      expect(savedExpense.id, expense.id);
      expect(savedExpense.amount.amountInCents, 10000);
      expect(savedExpense.note, 'Тестовый расход');

      // Проверяем, что расход появляется в списке
      final expenses = await expensesRepo.fetchExpenses();
      expect(expenses.length, greaterThan(0));
      expect(expenses.any((e) => e.id == expense.id), isTrue);
    });

    testWidgets('добавление расхода через форму и проверка в списке',
        (WidgetTester tester) async {
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
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
        ],
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ru')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: const NewExpensePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Вводим сумму
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '100.50');
      await tester.pump();

      // Нажимаем кнопку сохранения
      final saveButton = find.text('Сохранить');
      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Проверяем, что расход добавлен
      final expenses = await expensesRepo.fetchExpenses();
      expect(expenses.length, greaterThan(0));
      expect(expenses.any((e) => e.amount.amount == 100.50), isTrue);
    });

    testWidgets('редактирование расхода: изменение суммы и заметки',
        (WidgetTester tester) async {
      // Создаём тестовую категорию
      final category = Category(
        name: 'Тестовая категория',
        colorValue: 0xFF4CAF50,
        kind: CategoryKind.expense,
      );
      await categoriesRepo.upsertMany([category]);

      // Создаём исходный расход
      final originalExpense = Expense(
        id: Uuid().v4(),
        amount: Money(amountInCents: 10000, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: category.id,
        note: 'Исходная заметка',
      );
      await expensesRepo.upsertExpense(originalExpense);

      // Проверяем, что расход сохранён
      final savedExpense = await expensesRepo.getExpense(originalExpense.id);
      expect(savedExpense.amount.amountInCents, 10000);
      expect(savedExpense.note, 'Исходная заметка');

      // Обновляем расход
      final updatedExpense = originalExpense.copyWith(
        amount: Money(amountInCents: 20000, currencyCode: 'KZT'),
        note: 'Обновлённая заметка',
      );
      await expensesRepo.upsertExpense(updatedExpense);

      // Проверяем, что расход обновлён
      final updated = await expensesRepo.getExpense(originalExpense.id);
      expect(updated.amount.amountInCents, 20000);
      expect(updated.note, 'Обновлённая заметка');
      expect(updated.id, originalExpense.id); // ID должен остаться прежним
    });

    testWidgets('редактирование расхода: изменение типа и категории',
        (WidgetTester tester) async {
      // Создаём тестовые категории
      final expenseCategory = Category(
        name: 'Расходы',
        colorValue: 0xFF4CAF50,
        kind: CategoryKind.expense,
      );
      final incomeCategory = Category(
        name: 'Доходы',
        colorValue: 0xFF2196F3,
        kind: CategoryKind.income,
      );
      await categoriesRepo.upsertMany([expenseCategory, incomeCategory]);

      // Создаём исходный расход
      final originalExpense = Expense(
        id: Uuid().v4(),
        amount: Money(amountInCents: 10000, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: expenseCategory.id,
      );
      await expensesRepo.upsertExpense(originalExpense);

      // Меняем тип на доход и категорию
      final updatedExpense = originalExpense.copyWith(
        type: ExpenseType.income,
        categoryId: incomeCategory.id,
      );
      await expensesRepo.upsertExpense(updatedExpense);

      // Проверяем изменения
      final updated = await expensesRepo.getExpense(originalExpense.id);
      expect(updated.type.isIncome, isTrue);
      expect(updated.categoryId, incomeCategory.id);
    });
  });
}
