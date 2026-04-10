import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_currency/features_currency.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import 'analytics_models.dart';
import 'analytics_period_provider.dart';
import 'smart_insights.dart';

/// Отфильтрованные по периоду аналитики операции.
///
/// Слушает [expensesStreamProvider] через [AsyncValue], а не [StreamProvider.future]:
/// иначе после первого эмита стрима `future` уже завершён и провайдеры не
/// пересчитываются при новых данных — экран «Анализ» остаётся пустым/устаревшим.
final filteredExpensesProvider =
    Provider.autoDispose<List<Expense>>((ref) {
  final periodState = ref.watch(analyticsPeriodProvider);
  final expensesAsync = ref.watch(expensesStreamProvider);
  final expenses = expensesAsync.valueOrNull ?? <Expense>[];

  final DateTime? from = periodState.fromDate;
  final DateTime? to = periodState.toDate;

  return expenses.where((Expense expense) {
    if (from != null && expense.occurredAt.isBefore(from)) return false;
    if (to != null && expense.occurredAt.isAfter(to)) return false;
    return true;
  }).toList();
});

// Провайдер для статистики за период
final analyticsStatsProvider =
    FutureProvider.autoDispose<AnalyticsStats>((ref) async {
  final List<Expense> expenses = ref.watch(filteredExpensesProvider);
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  // Конвертируем все суммы в валюту по умолчанию
  return AnalyticsStats.fromExpenses(
      expenses, defaultCurrency, currencyService);
});

// Провайдер для данных по категориям
final categoryStatsProvider =
    FutureProvider.autoDispose<List<CategoryStat>>((ref) async {
  final List<Expense> expenses = ref.watch(filteredExpensesProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  final List<Category> categories = categoriesAsync.valueOrNull ?? <Category>[];
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  // Конвертируем все суммы в валюту по умолчанию
  return CategoryStat.fromExpenses(
      expenses, categories, defaultCurrency, currencyService);
});

// Провайдер для данных по месяцам/дням (зависит от периода)
final timeStatsProvider =
    FutureProvider.autoDispose<List<TimeStat>>((ref) async {
  final List<Expense> expenses = ref.watch(filteredExpensesProvider);
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
  final List<Expense> currentExpenses = ref.watch(filteredExpensesProvider);
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
  final expensesAsync = ref.watch(expensesStreamProvider);
  final List<Expense> allExpenses =
      expensesAsync.valueOrNull ?? <Expense>[];

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
  final List<Expense> currentExpenses = ref.watch(filteredExpensesProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  final List<Category> categories =
      categoriesAsync.valueOrNull ?? <Category>[];
  final defaultCurrency = ref.watch(defaultCurrencyProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  final from = periodState.fromDate;
  final to = periodState.toDate;

  if (from == null || to == null) return [];

  // Получаем расходы предыдущего периода
  final duration = to.difference(from);
  final previousFrom = from.subtract(duration);
  final previousTo = from.subtract(const Duration(seconds: 1));

  final expensesAsync = ref.watch(expensesStreamProvider);
  final List<Expense> allExpenses =
      expensesAsync.valueOrNull ?? <Expense>[];
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
  final List<Expense> expenses = ref.watch(filteredExpensesProvider);
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
  final List<Expense> expenses = ref.watch(filteredExpensesProvider);
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
  final List<Expense> expenses = ref.watch(filteredExpensesProvider);
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
