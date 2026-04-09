import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_models/shared_models.dart';
import 'package:data_core/data_core.dart';
import 'package:local_db/local_db.dart';

/// Сервис для создания и восстановления бэкапов
class BackupService {
  final AppDatabase database;
  final ExpensesRepository expensesRepo;
  final CategoriesRepository categoriesRepo;
  final BudgetsRepository? budgetsRepo;
  final DebtsRepository? debtsRepo;
  final CategoryRulesRepository? categoryRulesRepo;
  final RecurringExpensesRepository? recurringExpensesRepo;

  BackupService({
    required this.database,
    required this.expensesRepo,
    required this.categoriesRepo,
    this.budgetsRepo,
    this.debtsRepo,
    this.categoryRulesRepo,
    this.recurringExpensesRepo,
  });

  /// Создаёт бэкап всех данных в JSON файл
  Future<File> createBackup() async {
    final expenses = await expensesRepo.fetchExpenses();
    final categories = await categoriesRepo.fetchAll();

    final backupData = {
      'version': '2.0', // Обновлена версия для поддержки всех данных
      'createdAt': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
    };

    // Добавляем бюджеты, если репозиторий доступен
    if (budgetsRepo != null) {
      final budgets = await budgetsRepo!.fetchBudgets();
      backupData['budgets'] = budgets.map((b) => b.toJson()).toList();
    }

    // Добавляем долги, если репозиторий доступен
    if (debtsRepo != null) {
      final debts = await debtsRepo!.fetchDebts();
      backupData['debts'] = debts.map((d) => d.toJson()).toList();
    }

    // Добавляем правила категоризации, если репозиторий доступен
    if (categoryRulesRepo != null) {
      final rules = await categoryRulesRepo!.fetchRules();
      backupData['categoryRules'] = rules.map((r) => r.toJson()).toList();
    }

    // Добавляем повторяющиеся расходы, если репозиторий доступен
    if (recurringExpensesRepo != null) {
      final recurring = await recurringExpensesRepo!.fetchAll();
      backupData['recurringExpenses'] = recurring.map((r) => r.toJson()).toList();
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'expense_tracker_backup_$timestamp.json';

    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(jsonString);

    return file;
  }

  /// Восстанавливает данные из бэкапа
  Future<BackupRestoreResult> restoreBackup(File backupFile) async {
    try {
      final jsonString = await backupFile.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Проверяем версию
      final version = data['version'] as String?;
      if (version == null) {
        return BackupRestoreResult(
          success: false,
          error: 'Invalid backup format: missing version',
        );
      }

      // Парсим данные
      final expensesList = data['expenses'] as List<dynamic>?;
      final categoriesList = data['categories'] as List<dynamic>?;
      final budgetsList = data['budgets'] as List<dynamic>?;
      final debtsList = data['debts'] as List<dynamic>?;
      final categoryRulesList = data['categoryRules'] as List<dynamic>?;
      final recurringExpensesList = data['recurringExpenses'] as List<dynamic>?;

      if (expensesList == null && categoriesList == null && budgetsList == null && 
          debtsList == null && categoryRulesList == null && recurringExpensesList == null) {
        return BackupRestoreResult(
          success: false,
          error: 'Invalid backup format: no data found',
        );
      }

      int expensesCount = 0;
      int categoriesCount = 0;
      int budgetsCount = 0;
      int debtsCount = 0;
      int categoryRulesCount = 0;
      int recurringExpensesCount = 0;

      // Восстанавливаем категории
      if (categoriesList != null) {
        final categories = categoriesList
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
        
        await categoriesRepo.upsertMany(categories);
        categoriesCount = categories.length;
      }

      // Восстанавливаем транзакции
      if (expensesList != null) {
        final expenses = expensesList
            .map((json) => Expense.fromJson(json as Map<String, dynamic>))
            .toList();
        
        for (final expense in expenses) {
          await expensesRepo.upsertExpense(expense);
        }
        expensesCount = expenses.length;
      }

      // Восстанавливаем бюджеты
      if (budgetsList != null && budgetsRepo != null) {
        final budgets = budgetsList
            .map((json) => Budget.fromJson(json as Map<String, dynamic>))
            .toList();
        
        for (final budget in budgets) {
          await budgetsRepo!.upsertBudget(budget);
        }
        budgetsCount = budgets.length;
      }

      // Восстанавливаем долги
      if (debtsList != null && debtsRepo != null) {
        final debts = debtsList
            .map((json) => Debt.fromJson(json as Map<String, dynamic>))
            .toList();
        
        for (final debt in debts) {
          await debtsRepo!.upsertDebt(debt);
        }
        debtsCount = debts.length;
      }

      // Восстанавливаем правила категоризации
      if (categoryRulesList != null && categoryRulesRepo != null) {
        final rules = categoryRulesList
            .map((json) => CategoryRule.fromJson(json as Map<String, dynamic>))
            .toList();
        
        for (final rule in rules) {
          await categoryRulesRepo!.upsertRule(rule);
        }
        categoryRulesCount = rules.length;
      }

      // Восстанавливаем повторяющиеся расходы
      if (recurringExpensesList != null && recurringExpensesRepo != null) {
        final recurring = recurringExpensesList
            .map((json) => RecurringExpense.fromJson(json as Map<String, dynamic>))
            .toList();
        
        for (final expense in recurring) {
          await recurringExpensesRepo!.upsert(expense);
        }
        recurringExpensesCount = recurring.length;
      }

      return BackupRestoreResult(
        success: true,
        expensesCount: expensesCount,
        categoriesCount: categoriesCount,
        budgetsCount: budgetsCount,
        debtsCount: debtsCount,
        categoryRulesCount: categoryRulesCount,
        recurringExpensesCount: recurringExpensesCount,
      );
    } catch (e) {
      return BackupRestoreResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Получает информацию о бэкапе без полной загрузки
  Future<BackupInfo?> getBackupInfo(File backupFile) async {
    try {
      final jsonString = await backupFile.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final createdAt = data['createdAt'] as String?;
      final expensesList = data['expenses'] as List<dynamic>?;
      final categoriesList = data['categories'] as List<dynamic>?;
      final budgetsList = data['budgets'] as List<dynamic>?;
      final debtsList = data['debts'] as List<dynamic>?;
      final categoryRulesList = data['categoryRules'] as List<dynamic>?;
      final recurringExpensesList = data['recurringExpenses'] as List<dynamic>?;

      return BackupInfo(
        createdAt: createdAt != null ? DateTime.parse(createdAt) : null,
        expensesCount: expensesList?.length ?? 0,
        categoriesCount: categoriesList?.length ?? 0,
        budgetsCount: budgetsList?.length ?? 0,
        debtsCount: debtsList?.length ?? 0,
        categoryRulesCount: categoryRulesList?.length ?? 0,
        recurringExpensesCount: recurringExpensesList?.length ?? 0,
        fileSize: await backupFile.length(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Получает список всех бэкапов в директории документов
  Future<List<File>> listBackups() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync()
        .whereType<File>()
        .where((file) => file.path.contains('expense_tracker_backup_'))
        .where((file) => file.path.endsWith('.json'))
        .toList();
    
    // Сортируем по дате создания (новые первыми)
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    
    return files;
  }

  /// Удаляет бэкап
  Future<bool> deleteBackup(File backupFile) async {
    try {
      await backupFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Результат восстановления бэкапа
class BackupRestoreResult {
  const BackupRestoreResult({
    required this.success,
    this.error,
    this.expensesCount = 0,
    this.categoriesCount = 0,
    this.budgetsCount = 0,
    this.debtsCount = 0,
    this.categoryRulesCount = 0,
    this.recurringExpensesCount = 0,
  });

  final bool success;
  final String? error;
  final int expensesCount;
  final int categoriesCount;
  final int budgetsCount;
  final int debtsCount;
  final int categoryRulesCount;
  final int recurringExpensesCount;
}

/// Информация о бэкапе
class BackupInfo {
  const BackupInfo({
    this.createdAt,
    required this.expensesCount,
    required this.categoriesCount,
    this.budgetsCount = 0,
    this.debtsCount = 0,
    this.categoryRulesCount = 0,
    this.recurringExpensesCount = 0,
    required this.fileSize,
  });

  final DateTime? createdAt;
  final int expensesCount;
  final int categoriesCount;
  final int budgetsCount;
  final int debtsCount;
  final int categoryRulesCount;
  final int recurringExpensesCount;
  final int fileSize;

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

