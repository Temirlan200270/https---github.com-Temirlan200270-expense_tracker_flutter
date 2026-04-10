import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../tables/tables.dart';

// Сгенерируй часть через build_runner:
// dart run build_runner build --delete-conflicting-outputs -p packages/local_db
part 'app_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(docsDir.path, 'expenses.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [ExpensesTable, CategoriesTable, RecurringExpensesTable, BudgetsTable, CategoryRulesTable, DebtsTable, InsightFeedbackTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createIndexes(m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await _createIndexes(m);
        }
        if (from < 3) {
          // Создаём таблицу для повторяющихся транзакций
          // Используем SQL напрямую, так как типы ещё не сгенерированы
          await customStatement('''
            CREATE TABLE IF NOT EXISTS recurring_expenses (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              amount_cents INTEGER NOT NULL,
              currency_code TEXT NOT NULL,
              type TEXT NOT NULL,
              recurrence_type TEXT NOT NULL,
              start_date INTEGER NOT NULL,
              end_date INTEGER,
              category_id TEXT,
              note TEXT,
              is_active INTEGER NOT NULL DEFAULT 1,
              last_generated INTEGER,
              next_occurrence INTEGER,
              is_deleted INTEGER NOT NULL DEFAULT 0,
              deleted_at INTEGER,
              created_at INTEGER NOT NULL,
              updated_at INTEGER
            )
          ''');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_recurring_expenses_next_occurrence ON recurring_expenses(next_occurrence)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_recurring_expenses_is_active ON recurring_expenses(is_active)');
        }
        if (from < 4) {
          // Создаём таблицу для бюджетов
          await customStatement('''
            CREATE TABLE IF NOT EXISTS budgets (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              limit_cents INTEGER NOT NULL,
              currency_code TEXT NOT NULL,
              period TEXT NOT NULL,
              category_id TEXT,
              is_active INTEGER NOT NULL DEFAULT 1,
              warning_percent INTEGER NOT NULL DEFAULT 80,
              notifications_enabled INTEGER NOT NULL DEFAULT 1,
              is_deleted INTEGER NOT NULL DEFAULT 0,
              deleted_at INTEGER,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
              updated_at INTEGER
            )
          ''');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_budgets_category_id ON budgets(category_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_budgets_is_active ON budgets(is_active)');
        }
        if (from < 5) {
          // Создаём таблицу для правил автокатегоризации
          await customStatement('''
            CREATE TABLE IF NOT EXISTS category_rules (
              id TEXT NOT NULL PRIMARY KEY,
              keyword TEXT NOT NULL,
              category_id TEXT NOT NULL,
              priority INTEGER NOT NULL DEFAULT 0,
              case_sensitive INTEGER NOT NULL DEFAULT 0,
              is_active INTEGER NOT NULL DEFAULT 1,
              match_count INTEGER NOT NULL DEFAULT 0,
              last_used_at INTEGER,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
              updated_at INTEGER
            )
          ''');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_category_rules_keyword ON category_rules(keyword)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_category_rules_category_id ON category_rules(category_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_category_rules_is_active ON category_rules(is_active)');
        }
        if (from < 6) {
          // Создаём таблицу для долгов
          await customStatement('''
            CREATE TABLE IF NOT EXISTS debts (
              id TEXT NOT NULL PRIMARY KEY,
              person_name TEXT NOT NULL,
              total_amount_cents INTEGER NOT NULL,
              repaid_amount_cents INTEGER NOT NULL DEFAULT 0,
              currency_code TEXT NOT NULL,
              type TEXT NOT NULL,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
              due_date INTEGER,
              is_closed INTEGER NOT NULL DEFAULT 0,
              comment TEXT,
              updated_at INTEGER,
              deleted_at INTEGER,
              is_deleted INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_debts_type ON debts(type)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_debts_is_closed ON debts(is_closed)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_debts_is_deleted ON debts(is_deleted)');
        }
        if (from < 7) {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS insight_feedback (
              id TEXT NOT NULL PRIMARY KEY,
              insight_id TEXT NOT NULL,
              feedback_type INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_insight_feedback_insight_id ON insight_feedback(insight_id)',
          );
        }
        if (from < 8) {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS insight_feedback_v8 (
              id TEXT NOT NULL PRIMARY KEY,
              fingerprint TEXT NOT NULL,
              useful INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await customStatement('''
            INSERT INTO insight_feedback_v8 (id, fingerprint, useful, created_at)
            SELECT id, insight_id,
              CASE feedback_type WHEN 0 THEN 1 ELSE 0 END,
              created_at
            FROM insight_feedback
          ''');
          await customStatement('DROP TABLE insight_feedback');
          await customStatement(
            'ALTER TABLE insight_feedback_v8 RENAME TO insight_feedback',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_insight_feedback_fingerprint ON insight_feedback(fingerprint)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_insight_feedback_created_at ON insight_feedback(created_at)',
          );
        }
      },
    );
  }

  Future<void> _createIndexes(Migrator m) async {
    // Индекс по дате для быстрой фильтрации по периоду
    await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_occurred_at ON expenses(occurred_at)');
    
    // Индекс по категории для фильтрации
    await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses(category_id)');
    
    // Индекс по сумме для сортировки и фильтрации
    await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_amount ON expenses(amount_cents)');
    
    // Составной индекс для частых запросов: дата + isDeleted
    await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_occurred_deleted ON expenses(occurred_at, is_deleted)');
  }

  Future<void> clearAll() async {
    await transaction(() async {
      await delete(expensesTable).go();
      await delete(categoriesTable).go();
    });
  }
}

