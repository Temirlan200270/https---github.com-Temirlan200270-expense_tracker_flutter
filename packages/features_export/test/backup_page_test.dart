import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_export/src/presentation/pages/backup_page.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_db/local_db.dart';

void main() {
  group('BackupPage Widget Tests', () {
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

    testWidgets('отображает заголовок и основные секции', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          expensesRepositoryProvider.overrideWithValue(expensesRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          appDatabaseProvider.overrideWithValue(database),
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
              home: const BackupPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем заголовок
      expect(find.text('Бэкапы'), findsOneWidget);

      // Проверяем основные секции
      expect(find.text('Создать бэкап'), findsOneWidget);
      expect(find.text('Восстановить'), findsOneWidget);
      expect(find.text('Существующие бэкапы'), findsOneWidget);
    });

    testWidgets('отображает кнопки создания и восстановления', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          expensesRepositoryProvider.overrideWithValue(expensesRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          appDatabaseProvider.overrideWithValue(database),
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
              home: const BackupPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем кнопки
      expect(find.text('Создать бэкап'), findsOneWidget);
      expect(find.text('Выбрать файл'), findsOneWidget);
    });

    testWidgets('отображает пустое состояние когда нет бэкапов', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          expensesRepositoryProvider.overrideWithValue(expensesRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          appDatabaseProvider.overrideWithValue(database),
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
              home: const BackupPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем сообщение об отсутствии бэкапов
      expect(find.text('Нет созданных бэкапов'), findsOneWidget);
    });

    testWidgets('отображает описание функций', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          expensesRepositoryProvider.overrideWithValue(expensesRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          appDatabaseProvider.overrideWithValue(database),
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
              home: const BackupPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем описания
      expect(
        find.textContaining('Создайте резервную копию'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Восстановите данные'),
        findsOneWidget,
      );
    });
  });
}

