import 'package:data_core/data_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_db/local_db.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_api/sync_api.dart';

import 'src/app.dart';
import 'src/providers.dart';
import 'src/settings/settings_providers.dart';

Future<void> bootstrapExpenseTrackerApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final database = AppDatabase();
  final expensesRepo = LocalExpensesRepository(database);
  final categoriesRepo = LocalCategoriesRepository(database);
  final recurringExpensesRepo = LocalRecurringExpensesRepository(database);

  await _seedCategories(categoriesRepo);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(database),
      expensesRepositoryProvider.overrideWithValue(expensesRepo),
      categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
      recurringExpensesRepositoryProvider.overrideWithValue(recurringExpensesRepo),
      syncClientProvider.overrideWithValue(MockSyncClient()),
      syncServiceProvider.overrideWith((ref) => ExampleSyncService(ref.read(syncClientProvider))),
    ],
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: UncontrolledProviderScope(
        container: container,
        child: const ExpenseTrackerApp(),
      ),
    ),
  );
}

Future<void> _seedCategories(CategoriesRepository repository) async {
  final existing = await repository.fetchAll();
  if (existing.isNotEmpty) return;

  final defaults = <Category>[
    ...DefaultCategories.expenses(),
    ...DefaultCategories.incomes(),
  ];
  await repository.upsertMany(defaults);
}

