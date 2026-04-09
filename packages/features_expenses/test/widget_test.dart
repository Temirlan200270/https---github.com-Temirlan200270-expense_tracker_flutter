import 'package:easy_localization/easy_localization.dart';
import 'package:features_expenses/src/presentation/pages/expenses_list_page.dart';
import 'package:features_expenses/src/presentation/pages/new_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('ExpensesListPage Widget Tests', () {
    testWidgets('отображает заголовок и кнопки действий', (WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ru')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: ProviderScope(
            child: MaterialApp(
              home: const ExpensesListPage(),
            ),
          ),
        ),
      );

      expect(find.text('Расходы'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('отображает пустое состояние когда нет расходов', (WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ru')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: ProviderScope(
            child: MaterialApp(
              home: const ExpensesListPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие иконки пустого состояния
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    });
  });

  group('NewExpensePage Widget Tests', () {
    testWidgets('отображает форму добавления расхода', (WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ru')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: ProviderScope(
            child: MaterialApp(
              home: const NewExpensePage(),
            ),
          ),
        ),
      );

      expect(find.text('Новая операция'), findsOneWidget);
      expect(find.text('Сумма'), findsOneWidget);
      expect(find.text('Категория'), findsOneWidget);
      expect(find.text('Дата'), findsOneWidget);
      expect(find.text('Заметка'), findsOneWidget);
    });

    testWidgets('валидация суммы - пустое поле', (WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ru')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: ProviderScope(
            child: MaterialApp(
              home: const NewExpensePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Находим кнопку сохранения
      final saveButton = find.text('Сохранить');
      expect(saveButton, findsOneWidget);

      // Пытаемся сохранить без ввода суммы
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Должна появиться ошибка валидации
      expect(find.text('Введите сумму'), findsOneWidget);
    });

    testWidgets('отображает форму редактирования с заполненными данными', (WidgetTester tester) async {
      final expense = Expense(
        id: 'test-expense-1',
        amount: Money(amountInCents: 50000, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime(2024, 1, 15),
        categoryId: 'test-category',
        note: 'Тестовая заметка',
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ru')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: ProviderScope(
            child: MaterialApp(
              home: NewExpensePage(expense: expense),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем заголовок
      expect(find.text('Редактировать операцию'), findsOneWidget);

      // Проверяем, что поля заполнены
      final amountField = find.byType(TextFormField).first;
      expect(tester.widget<TextFormField>(amountField).controller?.text, '500.0');

      // Проверяем наличие кнопки удаления
      expect(find.text('Удалить'), findsOneWidget);
    });

    testWidgets('валидация суммы - некорректное значение', (WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ru')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: ProviderScope(
            child: MaterialApp(
              home: const NewExpensePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Вводим некорректную сумму
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, 'abc');
      await tester.pump();

      // Нажимаем кнопку сохранения
      final saveButton = find.text('Сохранить');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Должна появиться ошибка валидации
      expect(find.text('Введите корректную сумму'), findsOneWidget);
    });
  });
}

