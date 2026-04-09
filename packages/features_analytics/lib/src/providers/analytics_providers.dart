import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_currency/features_currency.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import 'analytics_models.dart';
import 'analytics_period_provider.dart';
import 'smart_insights.dart';

// Провайдер для отфильтрованных расходов
final filteredExpensesProvider =
    FutureProvider.autoDispose<List<Expense>>((ref) async {
  final periodState = ref.watch(analyticsPeriodProvider);
  final expenses = await ref.watch(expensesStreamProvider.future);

  final from = periodState.fromDate;
  final to = periodState.toDate;

  final filtered = expenses.where((expense) {
    if (from != null && expense.occurredAt.isBefore(from)) return false;
    if (to != null && expense.occurredAt.isAfter(to)) return false;
    return true;
  }).toList();
  
  // Логируем для отладки (только если период не "все время")
  if (from != null || to != null) {
    print('📊 Фильтр аналитики: период ${from?.toString() ?? "начало"} - ${to?.toString() ?? "конец"}');
    print('   Всего транзакций: ${expenses.length}');
    print('   Отфильтровано: ${filtered.length}');
  }
  
  return filtered;
});

// Провайдер для статистики за период
final analyticsStatsProvider =
    FutureProvider.autoDispose<AnalyticsStats>((ref) async {
  final expenses = await ref.watch(filteredExpensesProvider.future);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  // Конвертируем все суммы в валюту по умолчанию
  return AnalyticsStats.fromExpenses(
      expenses, defaultCurrency, currencyService);
});

// Провайдер для данных по категориям
final categoryStatsProvider =
    FutureProvider.autoDispose<List<CategoryStat>>((ref) async {
  final expenses = await ref.watch(filteredExpensesProvider.future);
  final categories = await ref.watch(categoriesStreamProvider.future);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  // Конвертируем все суммы в валюту по умолчанию
  return CategoryStat.fromExpenses(
      expenses, categories, defaultCurrency, currencyService);
});

// Провайдер для данных по месяцам/дням (зависит от периода)
final timeStatsProvider =
    FutureProvider.autoDispose<List<TimeStat>>((ref) async {
  final expenses = await ref.watch(filteredExpensesProvider.future);
  final periodState = ref.watch(analyticsPeriodProvider);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  // Для коротких периодов (день, неделя) показываем по дням, для длинных - по месяцам
  final groupByDays = periodState.period == AnalyticsPeriod.today ||
      periodState.period == AnalyticsPeriod.week;

  return TimeStat.fromExpenses(
    expenses,
    defaultCurrency,
    currencyService,
    groupByDays: groupByDays,
  );
});

// Провайдер для сравнения с предыдущим периодом
final comparisonStatsProvider =
    FutureProvider.autoDispose<ComparisonStats?>((ref) async {
  final periodState = ref.watch(analyticsPeriodProvider);
  final currentExpenses = await ref.watch(filteredExpensesProvider.future);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  // Вычисляем предыдущий период
  final from = periodState.fromDate;
  final to = periodState.toDate;

  if (from == null || to == null) return null; // Нельзя сравнить "все время"

  final duration = to.difference(from);
  final previousFrom = from.subtract(duration);
  final previousTo = from.subtract(const Duration(seconds: 1));

  // Получаем все расходы
  final allExpenses = await ref.watch(expensesStreamProvider.future);

  // Фильтруем предыдущий период
  final previousExpenses = allExpenses.where((expense) {
    return expense.occurredAt.isAfter(previousFrom) &&
        expense.occurredAt.isBefore(previousTo);
  }).toList();

  final currentStats = await AnalyticsStats.fromExpenses(
    currentExpenses,
    defaultCurrency,
    currencyService,
  );

  final previousStats = await AnalyticsStats.fromExpenses(
    previousExpenses,
    defaultCurrency,
    currencyService,
  );

  return ComparisonStats(
    current: currentStats,
    previous: previousStats,
  );
});

// Провайдер для умных инсайтов
final smartInsightsProvider =
    FutureProvider.autoDispose<List<SmartInsight>>((ref) async {
  final periodState = ref.watch(analyticsPeriodProvider);
  final currentExpenses = await ref.watch(filteredExpensesProvider.future);
  final categories = await ref.watch(categoriesStreamProvider.future);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  final from = periodState.fromDate;
  final to = periodState.toDate;

  if (from == null || to == null) return [];

  // Получаем расходы предыдущего периода
  final duration = to.difference(from);
  final previousFrom = from.subtract(duration);
  final previousTo = from.subtract(const Duration(seconds: 1));

  final allExpenses = await ref.watch(expensesStreamProvider.future);
  final previousExpenses = allExpenses.where((expense) {
    return expense.occurredAt.isAfter(previousFrom) &&
        expense.occurredAt.isBefore(previousTo);
  }).toList();

  return SmartInsightsService.generateInsights(
    expenses: currentExpenses,
    previousPeriodExpenses: previousExpenses,
    categories: categories,
    targetCurrency: defaultCurrency,
    currencyService: currencyService,
    periodStart: from,
    periodEnd: to,
  );
});

// Провайдер для средних показателей
final averageStatsProvider =
    FutureProvider.autoDispose<AverageStats?>((ref) async {
  final periodState = ref.watch(analyticsPeriodProvider);
  final expenses = await ref.watch(filteredExpensesProvider.future);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  final from = periodState.fromDate;
  final to = periodState.toDate;

  if (from == null || to == null || expenses.isEmpty) return null;

  return SmartInsightsService.calculateAverages(
    expenses: expenses,
    targetCurrency: defaultCurrency,
    currencyService: currencyService,
    periodStart: from,
    periodEnd: to,
  );
});

// Провайдер для паттернов трат
final spendingPatternsProvider =
    FutureProvider.autoDispose<SpendingPattern?>((ref) async {
  final expenses = await ref.watch(filteredExpensesProvider.future);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  if (expenses.isEmpty) return null;

  return SmartInsightsService.analyzePatterns(
    expenses: expenses,
    targetCurrency: defaultCurrency,
    currencyService: currencyService,
  );
});

// Провайдер для прогноза
final forecastProvider = FutureProvider.autoDispose<Forecast?>((ref) async {
  final periodState = ref.watch(analyticsPeriodProvider);
  final expenses = await ref.watch(filteredExpensesProvider.future);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  final from = periodState.fromDate;
  final to = periodState.toDate;

  if (from == null || to == null) return null;

  return SmartInsightsService.createForecast(
    expenses: expenses,
    targetCurrency: defaultCurrency,
    currencyService: currencyService,
    periodStart: from,
    periodEnd: to,
  );
});
