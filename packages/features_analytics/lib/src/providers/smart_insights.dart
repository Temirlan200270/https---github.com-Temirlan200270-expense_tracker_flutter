import 'dart:math';

import 'package:features_currency/features_currency.dart';
import 'package:shared_models/shared_models.dart';

/// Типы инсайтов
enum InsightType {
  spending,
  saving,
  trend,
  warning,
  achievement,
  pattern,
  tip,
}

/// Приоритет инсайта
enum InsightPriority {
  low,
  medium,
  high,
}

/// Умный инсайт
class SmartInsight {
  const SmartInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    this.value,
    this.percentage,
    this.trend,
    this.categoryName,
  });

  final InsightType type;
  final String title;
  final String description;
  final InsightPriority priority;
  final double? value;
  final double? percentage;
  final TrendDirection? trend;
  final String? categoryName;
}

/// Направление тренда
enum TrendDirection {
  up,
  down,
  stable,
}

/// Средние показатели
class AverageStats {
  const AverageStats({
    required this.dailyExpense,
    required this.dailyIncome,
    required this.weeklyExpense,
    required this.weeklyIncome,
    required this.monthlyExpense,
    required this.monthlyIncome,
    required this.daysWithExpenses,
    required this.totalDays,
  });

  final double dailyExpense;
  final double dailyIncome;
  final double weeklyExpense;
  final double weeklyIncome;
  final double monthlyExpense;
  final double monthlyIncome;
  final int daysWithExpenses;
  final int totalDays;

  /// Частота расходов (дни с расходами / всего дней)
  double get expenseFrequency => totalDays > 0 ? daysWithExpenses / totalDays : 0;
}

/// Паттерны трат
class SpendingPattern {
  const SpendingPattern({
    required this.topSpendingDay,
    required this.topSpendingDayAmount,
    required this.leastSpendingDay,
    required this.leastSpendingDayAmount,
    required this.weekendVsWeekday,
    required this.biggestTransaction,
    required this.smallestTransaction,
    required this.averageTransaction,
  });

  final String topSpendingDay;
  final double topSpendingDayAmount;
  final String leastSpendingDay;
  final double leastSpendingDayAmount;
  final double weekendVsWeekday; // > 1 значит больше тратим в выходные
  final double biggestTransaction;
  final double smallestTransaction;
  final double averageTransaction;
}

/// Прогноз на конец периода
class Forecast {
  const Forecast({
    required this.projectedExpenses,
    required this.projectedIncome,
    required this.projectedBalance,
    required this.confidence,
    required this.daysRemaining,
    required this.trend,
  });

  final double projectedExpenses;
  final double projectedIncome;
  final double projectedBalance;
  final double confidence; // 0-1
  final int daysRemaining;
  final TrendDirection trend;
}

/// Сервис для генерации умных инсайтов
class SmartInsightsService {
  static final _dayNames = {
    DateTime.monday: 'Понедельник',
    DateTime.tuesday: 'Вторник',
    DateTime.wednesday: 'Среда',
    DateTime.thursday: 'Четверг',
    DateTime.friday: 'Пятница',
    DateTime.saturday: 'Суббота',
    DateTime.sunday: 'Воскресенье',
  };

  /// Генерирует список умных инсайтов
  static Future<List<SmartInsight>> generateInsights({
    required List<Expense> expenses,
    required List<Expense> previousPeriodExpenses,
    required List<Category> categories,
    required String targetCurrency,
    required CurrencyService currencyService,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final insights = <SmartInsight>[];
    final rates = await currencyService.getExchangeRates();

    // Конвертируем суммы
    double convertAmount(Expense e) {
      double amount = e.amount.amount;
      if (e.amount.currencyCode != targetCurrency) {
        final rate = _getRate(e.amount.currencyCode, targetCurrency, rates);
        if (rate != null) amount *= rate;
      }
      return amount;
    }

    final currentExpensesList = expenses.where((e) => e.type.isExpense).toList();
    final currentIncomeList = expenses.where((e) => e.type.isIncome).toList();
    final previousExpensesList = previousPeriodExpenses.where((e) => e.type.isExpense).toList();

    final currentTotalExpenses = currentExpensesList.fold<double>(0, (sum, e) => sum + convertAmount(e));
    final currentTotalIncome = currentIncomeList.fold<double>(0, (sum, e) => sum + convertAmount(e));
    final previousTotalExpenses = previousExpensesList.fold<double>(0, (sum, e) => sum + convertAmount(e));

    // 1. Сравнение с предыдущим периодом
    if (previousTotalExpenses > 0) {
      final changePercent = ((currentTotalExpenses - previousTotalExpenses) / previousTotalExpenses) * 100;
      
      if (changePercent > 20) {
        insights.add(SmartInsight(
          type: InsightType.warning,
          title: 'Расходы выросли',
          description: 'Вы потратили на ${changePercent.abs().toStringAsFixed(0)}% больше, чем в прошлый период',
          priority: InsightPriority.high,
          percentage: changePercent,
          trend: TrendDirection.up,
        ));
      } else if (changePercent < -20) {
        insights.add(SmartInsight(
          type: InsightType.achievement,
          title: 'Отличная экономия!',
          description: 'Расходы снизились на ${changePercent.abs().toStringAsFixed(0)}% по сравнению с прошлым периодом',
          priority: InsightPriority.high,
          percentage: changePercent,
          trend: TrendDirection.down,
        ));
      }
    }

    // 2. Баланс доходов/расходов
    if (currentTotalIncome > 0 && currentTotalExpenses > 0) {
      final savingsRate = ((currentTotalIncome - currentTotalExpenses) / currentTotalIncome) * 100;
      
      if (savingsRate > 30) {
        insights.add(SmartInsight(
          type: InsightType.achievement,
          title: 'Высокая норма сбережений',
          description: 'Вы сохраняете ${savingsRate.toStringAsFixed(0)}% от дохода — отличный результат!',
          priority: InsightPriority.medium,
          percentage: savingsRate,
        ));
      } else if (savingsRate < 0) {
        insights.add(SmartInsight(
          type: InsightType.warning,
          title: 'Расходы превышают доходы',
          description: 'Рекомендуем пересмотреть бюджет — расходы больше доходов на ${savingsRate.abs().toStringAsFixed(0)}%',
          priority: InsightPriority.high,
          percentage: savingsRate,
        ));
      }
    }

    // 3. Топ категория расходов
    if (currentExpensesList.isNotEmpty) {
      final categoryMap = {for (var c in categories) c.id: c};
      final categoryTotals = <String, double>{};
      
      for (final expense in currentExpensesList) {
        if (expense.categoryId != null) {
          categoryTotals[expense.categoryId!] = 
              (categoryTotals[expense.categoryId!] ?? 0) + convertAmount(expense);
        }
      }

      if (categoryTotals.isNotEmpty) {
        final topCategoryId = categoryTotals.entries
            .reduce((a, b) => a.value > b.value ? a : b).key;
        final topCategory = categoryMap[topCategoryId];
        final topAmount = categoryTotals[topCategoryId]!;
        final percentage = (topAmount / currentTotalExpenses) * 100;

        if (percentage > 40) {
          insights.add(SmartInsight(
            type: InsightType.pattern,
            title: 'Основные траты',
            description: '${topCategory?.name ?? "Категория"} составляет ${percentage.toStringAsFixed(0)}% всех расходов',
            priority: InsightPriority.medium,
            categoryName: topCategory?.name,
            percentage: percentage,
            value: topAmount,
          ));
        }
      }
    }

    // 4. Средний чек
    if (currentExpensesList.isNotEmpty) {
      final avgTransaction = currentTotalExpenses / currentExpensesList.length;
      
      // Находим транзакции значительно выше среднего
      final bigTransactions = currentExpensesList
          .where((e) => convertAmount(e) > avgTransaction * 3)
          .toList();

      if (bigTransactions.isNotEmpty) {
        insights.add(SmartInsight(
          type: InsightType.spending,
          title: 'Крупные траты',
          description: '${bigTransactions.length} транзакций значительно превышают средний чек',
          priority: InsightPriority.low,
          value: avgTransaction,
        ));
      }
    }

    // 5. Дни без расходов
    final daysInPeriod = periodEnd.difference(periodStart).inDays + 1;
    final daysWithExpenses = currentExpensesList
        .map((e) => DateTime(e.occurredAt.year, e.occurredAt.month, e.occurredAt.day))
        .toSet()
        .length;
    final daysWithoutExpenses = daysInPeriod - daysWithExpenses;

    if (daysWithoutExpenses > daysInPeriod * 0.3 && daysInPeriod > 7) {
      insights.add(SmartInsight(
        type: InsightType.achievement,
        title: 'Дни без трат',
        description: '$daysWithoutExpenses дней без расходов — хорошая дисциплина!',
        priority: InsightPriority.low,
      ));
    }

    // 6. Прогноз на конец месяца (если текущий месяц)
    final now = DateTime.now();
    if (periodStart.month == now.month && periodStart.year == now.year) {
      final daysPassed = now.day;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysRemaining = daysInMonth - daysPassed;

      if (daysPassed > 7 && daysRemaining > 0) {
        final dailyAverage = currentTotalExpenses / daysPassed;
        final projected = currentTotalExpenses + (dailyAverage * daysRemaining);

        insights.add(SmartInsight(
          type: InsightType.trend,
          title: 'Прогноз на месяц',
          description: 'При текущем темпе расходы составят примерно ${projected.toStringAsFixed(0)} $targetCurrency',
          priority: InsightPriority.medium,
          value: projected,
        ));
      }
    }

    // Сортируем по приоритету
    insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return insights;
  }

  /// Вычисляет средние показатели
  static Future<AverageStats> calculateAverages({
    required List<Expense> expenses,
    required String targetCurrency,
    required CurrencyService currencyService,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final rates = await currencyService.getExchangeRates();

    double convertAmount(Expense e) {
      double amount = e.amount.amount;
      if (e.amount.currencyCode != targetCurrency) {
        final rate = _getRate(e.amount.currencyCode, targetCurrency, rates);
        if (rate != null) amount *= rate;
      }
      return amount;
    }

    final totalDays = max(1, periodEnd.difference(periodStart).inDays + 1);
    final weeks = totalDays / 7;
    final months = totalDays / 30;

    double totalExpenses = 0;
    double totalIncome = 0;
    final daysWithExpenses = <String>{};

    for (final expense in expenses) {
      final amount = convertAmount(expense);
      if (expense.type.isExpense) {
        totalExpenses += amount;
        daysWithExpenses.add('${expense.occurredAt.year}-${expense.occurredAt.month}-${expense.occurredAt.day}');
      } else {
        totalIncome += amount;
      }
    }

    return AverageStats(
      dailyExpense: totalExpenses / totalDays,
      dailyIncome: totalIncome / totalDays,
      weeklyExpense: totalExpenses / max(1, weeks),
      weeklyIncome: totalIncome / max(1, weeks),
      monthlyExpense: totalExpenses / max(1, months),
      monthlyIncome: totalIncome / max(1, months),
      daysWithExpenses: daysWithExpenses.length,
      totalDays: totalDays,
    );
  }

  /// Анализирует паттерны трат
  static Future<SpendingPattern?> analyzePatterns({
    required List<Expense> expenses,
    required String targetCurrency,
    required CurrencyService currencyService,
  }) async {
    final expensesList = expenses.where((e) => e.type.isExpense).toList();
    if (expensesList.isEmpty) return null;

    final rates = await currencyService.getExchangeRates();

    double convertAmount(Expense e) {
      double amount = e.amount.amount;
      if (e.amount.currencyCode != targetCurrency) {
        final rate = _getRate(e.amount.currencyCode, targetCurrency, rates);
        if (rate != null) amount *= rate;
      }
      return amount;
    }

    // Траты по дням недели
    final dayTotals = <int, double>{};
    for (var i = 1; i <= 7; i++) {
      dayTotals[i] = 0;
    }

    double weekendTotal = 0;
    double weekdayTotal = 0;
    double minAmount = double.infinity;
    double maxAmount = 0;
    double totalAmount = 0;

    for (final expense in expensesList) {
      final amount = convertAmount(expense);
      final weekday = expense.occurredAt.weekday;
      
      dayTotals[weekday] = (dayTotals[weekday] ?? 0) + amount;
      
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        weekendTotal += amount;
      } else {
        weekdayTotal += amount;
      }

      if (amount < minAmount) minAmount = amount;
      if (amount > maxAmount) maxAmount = amount;
      totalAmount += amount;
    }

    final topDay = dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    final leastDay = dayTotals.entries.reduce((a, b) => a.value < b.value ? a : b);

    return SpendingPattern(
      topSpendingDay: _dayNames[topDay.key] ?? 'День ${topDay.key}',
      topSpendingDayAmount: topDay.value,
      leastSpendingDay: _dayNames[leastDay.key] ?? 'День ${leastDay.key}',
      leastSpendingDayAmount: leastDay.value,
      weekendVsWeekday: weekdayTotal > 0 ? (weekendTotal / 2) / (weekdayTotal / 5) : 0,
      biggestTransaction: maxAmount,
      smallestTransaction: minAmount == double.infinity ? 0 : minAmount,
      averageTransaction: totalAmount / expensesList.length,
    );
  }

  /// Создаёт прогноз
  static Future<Forecast?> createForecast({
    required List<Expense> expenses,
    required String targetCurrency,
    required CurrencyService currencyService,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final now = DateTime.now();
    if (now.isBefore(periodStart) || now.isAfter(periodEnd)) return null;

    final rates = await currencyService.getExchangeRates();

    double convertAmount(Expense e) {
      double amount = e.amount.amount;
      if (e.amount.currencyCode != targetCurrency) {
        final rate = _getRate(e.amount.currencyCode, targetCurrency, rates);
        if (rate != null) amount *= rate;
      }
      return amount;
    }

    final daysPassed = now.difference(periodStart).inDays + 1;
    final daysRemaining = periodEnd.difference(now).inDays;
    
    if (daysPassed < 3 || daysRemaining < 1) return null;

    double currentExpenses = 0;
    double currentIncome = 0;

    for (final expense in expenses) {
      final amount = convertAmount(expense);
      if (expense.type.isExpense) {
        currentExpenses += amount;
      } else {
        currentIncome += amount;
      }
    }

    final dailyExpenseRate = currentExpenses / daysPassed;
    final dailyIncomeRate = currentIncome / daysPassed;

    final projectedExpenses = currentExpenses + (dailyExpenseRate * daysRemaining);
    final projectedIncome = currentIncome + (dailyIncomeRate * daysRemaining);

    // Уверенность зависит от количества данных
    final confidence = min(1.0, daysPassed / 14);

    return Forecast(
      projectedExpenses: projectedExpenses,
      projectedIncome: projectedIncome,
      projectedBalance: projectedIncome - projectedExpenses,
      confidence: confidence,
      daysRemaining: daysRemaining,
      trend: projectedExpenses > projectedIncome 
          ? TrendDirection.down 
          : TrendDirection.up,
    );
  }

  static double? _getRate(String from, String to, Map<String, double> rates) {
    if (from == to) return 1.0;
    if (from == 'USD') return rates[to];
    if (to == 'USD') {
      final fromRate = rates[from];
      return fromRate != null ? 1.0 / fromRate : null;
    }
    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate != null && toRate != null) {
      return toRate / fromRate;
    }
    return null;
  }
}

