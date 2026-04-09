import 'package:features_currency/features_currency.dart';
import 'package:shared_models/shared_models.dart';

class AnalyticsStats {
  AnalyticsStats({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.expenseCount,
    required this.incomeCount,
  });

  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final int expenseCount;
  final int incomeCount;

  static Future<AnalyticsStats> fromExpenses(
    List<Expense> expenses,
    String targetCurrency,
    CurrencyService currencyService,
  ) async {
    // Получаем все курсы валют один раз
    final rates = await currencyService.getExchangeRates();
    
    double totalIncome = 0;
    double totalExpenses = 0;
    int expenseCount = 0;
    int incomeCount = 0;

    for (final expense in expenses) {
      // Конвертируем сумму в целевую валюту
      double amount = expense.amount.amount;
      final expenseCurrency = expense.amount.currencyCode;
      
      if (expenseCurrency != targetCurrency) {
        // Конвертируем через USD (базовая валюта API)
        double? rate;
        if (expenseCurrency == 'USD') {
          rate = rates[targetCurrency];
        } else if (targetCurrency == 'USD') {
          final fromRate = rates[expenseCurrency];
          rate = fromRate != null ? 1.0 / fromRate : null;
        } else {
          final fromRate = rates[expenseCurrency];
          final toRate = rates[targetCurrency];
          if (fromRate != null && toRate != null) {
            rate = toRate / fromRate;
          }
        }
        
        if (rate != null) {
          amount = amount * rate;
        }
        // Если курс недоступен, используем исходную сумму
      }

      if (expense.type.isIncome) {
        totalIncome += amount;
        incomeCount++;
      } else {
        totalExpenses += amount;
        expenseCount++;
      }
    }

    return AnalyticsStats(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: totalIncome - totalExpenses,
      expenseCount: expenseCount,
      incomeCount: incomeCount,
    );
  }
}

class CategoryStat {
  CategoryStat({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.count,
    required this.colorValue,
  });

  final String categoryId;
  final String categoryName;
  final double amount;
  final int count;
  final int colorValue;

  static Future<List<CategoryStat>> fromExpenses(
    List<Expense> expenses,
    List<Category> categories,
    String targetCurrency,
    CurrencyService currencyService,
  ) async {
    // Получаем все курсы валют один раз
    final rates = await currencyService.getExchangeRates();
    final Map<String, CategoryStatData> data = {};

    for (final expense in expenses) {
      if (expense.categoryId == null) continue;
      final categoryId = expense.categoryId!;
      
      // Конвертируем сумму в целевую валюту
      double amount = expense.amount.amount;
      final expenseCurrency = expense.amount.currencyCode;
      
      if (expenseCurrency != targetCurrency) {
        // Конвертируем через USD (базовая валюта API)
        double? rate;
        if (expenseCurrency == 'USD') {
          rate = rates[targetCurrency];
        } else if (targetCurrency == 'USD') {
          final fromRate = rates[expenseCurrency];
          rate = fromRate != null ? 1.0 / fromRate : null;
        } else {
          final fromRate = rates[expenseCurrency];
          final toRate = rates[targetCurrency];
          if (fromRate != null && toRate != null) {
            rate = toRate / fromRate;
          }
        }
        
        if (rate != null) {
          amount = amount * rate;
        }
      }

      data.putIfAbsent(
        categoryId,
        () => CategoryStatData(
          categoryId: categoryId,
          amount: 0,
          count: 0,
        ),
      );

      final stat = data[categoryId]!;
      stat.amount += amount;
      stat.count++;
    }

    final categoryMap = {for (final cat in categories) cat.id: cat};

    return data.entries.map((entry) {
      final category = categoryMap[entry.key];
      return CategoryStat(
        categoryId: entry.key,
        categoryName: category?.name ?? 'Без категории',
        amount: entry.value.amount,
        count: entry.value.count,
        colorValue: category?.colorValue ?? 0xFF9E9E9E,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }
}

class CategoryStatData {
  CategoryStatData({
    required this.categoryId,
    required this.amount,
    required this.count,
  });

  final String categoryId;
  double amount;
  int count;
}

class MonthlyStat {
  MonthlyStat({
    required this.month,
    required this.year,
    required this.income,
    required this.expenses,
  });

  final int month;
  final int year;
  final double income;
  final double expenses;

  static Future<List<MonthlyStat>> fromExpenses(
    List<Expense> expenses,
    String targetCurrency,
    CurrencyService currencyService,
  ) async {
    // Получаем все курсы валют один раз
    final rates = await currencyService.getExchangeRates();
    final Map<String, MonthlyStatData> data = {};

    for (final expense in expenses) {
      final date = expense.occurredAt;
      final key = '${date.year}-${date.month}';
      
      // Конвертируем сумму в целевую валюту
      double amount = expense.amount.amount;
      final expenseCurrency = expense.amount.currencyCode;
      
      if (expenseCurrency != targetCurrency) {
        // Конвертируем через USD (базовая валюта API)
        double? rate;
        if (expenseCurrency == 'USD') {
          rate = rates[targetCurrency];
        } else if (targetCurrency == 'USD') {
          final fromRate = rates[expenseCurrency];
          rate = fromRate != null ? 1.0 / fromRate : null;
        } else {
          final fromRate = rates[expenseCurrency];
          final toRate = rates[targetCurrency];
          if (fromRate != null && toRate != null) {
            rate = toRate / fromRate;
          }
        }
        
        if (rate != null) {
          amount = amount * rate;
        }
      }

      data.putIfAbsent(
        key,
        () => MonthlyStatData(
          month: date.month,
          year: date.year,
          income: 0,
          expenses: 0,
        ),
      );

      final stat = data[key]!;
      if (expense.type.isIncome) {
        stat.income += amount;
      } else {
        stat.expenses += amount;
      }
    }

    return data.values
        .map((d) => MonthlyStat(
              month: d.month,
              year: d.year,
              income: d.income,
              expenses: d.expenses,
            ))
        .toList()
      ..sort((a, b) {
        if (a.year != b.year) return a.year.compareTo(b.year);
        return a.month.compareTo(b.month);
      });
  }
}

class MonthlyStatData {
  MonthlyStatData({
    required this.month,
    required this.year,
    required this.income,
    required this.expenses,
  });

  final int month;
  final int year;
  double income;
  double expenses;
}

// Статистика по времени (дни или месяцы)
class TimeStat {
  TimeStat({
    required this.label,
    required this.date,
    required this.income,
    required this.expenses,
  });

  final String label;
  final DateTime date;
  final double income;
  final double expenses;

  static Future<List<TimeStat>> fromExpenses(
    List<Expense> expenses,
    String targetCurrency,
    CurrencyService currencyService, {
    required bool groupByDays,
  }) async {
    final rates = await currencyService.getExchangeRates();
    final Map<String, TimeStatData> data = {};

    for (final expense in expenses) {
      final date = expense.occurredAt;
      String key;
      String label;
      DateTime statDate;

      if (groupByDays) {
        key = '${date.year}-${date.month}-${date.day}';
        label = '${date.day}.${date.month}';
        statDate = DateTime(date.year, date.month, date.day);
      } else {
        key = '${date.year}-${date.month}';
        final monthNames = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 
                           'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
        label = '${monthNames[date.month - 1]} ${date.year}';
        statDate = DateTime(date.year, date.month, 1);
      }

      // Конвертируем сумму в целевую валюту
      double amount = expense.amount.amount;
      final expenseCurrency = expense.amount.currencyCode;

      if (expenseCurrency != targetCurrency) {
        double? rate;
        if (expenseCurrency == 'USD') {
          rate = rates[targetCurrency];
        } else if (targetCurrency == 'USD') {
          final fromRate = rates[expenseCurrency];
          rate = fromRate != null ? 1.0 / fromRate : null;
        } else {
          final fromRate = rates[expenseCurrency];
          final toRate = rates[targetCurrency];
          if (fromRate != null && toRate != null) {
            rate = toRate / fromRate;
          }
        }

        if (rate != null) {
          amount = amount * rate;
        }
      }

      data.putIfAbsent(
        key,
        () => TimeStatData(
          label: label,
          date: statDate,
          income: 0,
          expenses: 0,
        ),
      );

      final stat = data[key]!;
      if (expense.type.isIncome) {
        stat.income += amount;
      } else {
        stat.expenses += amount;
      }
    }

    return data.values
        .map((d) => TimeStat(
              label: d.label,
              date: d.date,
              income: d.income,
              expenses: d.expenses,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

class TimeStatData {
  TimeStatData({
    required this.label,
    required this.date,
    required this.income,
    required this.expenses,
  });

  final String label;
  final DateTime date;
  double income;
  double expenses;
}

// Сравнение с предыдущим периодом
class ComparisonStats {
  ComparisonStats({
    required this.current,
    required this.previous,
  });

  final AnalyticsStats current;
  final AnalyticsStats previous;

  double get incomeChange => current.totalIncome - previous.totalIncome;
  double get expensesChange => current.totalExpenses - previous.totalExpenses;
  double get balanceChange => current.balance - previous.balance;

  double get incomeChangePercent {
    if (previous.totalIncome == 0) return 0;
    return (incomeChange / previous.totalIncome) * 100;
  }

  double get expensesChangePercent {
    if (previous.totalExpenses == 0) return 0;
    return (expensesChange / previous.totalExpenses) * 100;
  }

  double get balanceChangePercent {
    if (previous.balance == 0) return 0;
    return (balanceChange / previous.balance.abs()) * 100;
  }
}

