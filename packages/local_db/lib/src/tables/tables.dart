import 'package:drift/drift.dart';

@DataClassName('ExpenseRow')
class ExpensesTable extends Table {
  @override
  String get tableName => 'expenses';

  TextColumn get id => text()();
  IntColumn get amountInCents => integer().named('amount_cents')();
  TextColumn get currencyCode => text().named('currency_code').withLength(min: 3, max: 3)();
  TextColumn get type => text().withLength(min: 6, max: 7)(); // income / expense
  DateTimeColumn get occurredAt => dateTime().named('occurred_at')();
  TextColumn get categoryId => text().named('category_id').nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isDeleted => boolean().named('is_deleted').withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  // Индексы будут добавлены позже через миграции.
}

@DataClassName('CategoryRow')
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  IntColumn get colorValue => integer().named('color_value')();
  TextColumn get kind => text().withLength(min: 6, max: 7)();
  BoolColumn get isDeleted => boolean().named('is_deleted').withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecurringExpenseRow')
class RecurringExpensesTable extends Table {
  @override
  String get tableName => 'recurring_expenses';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 128)();
  IntColumn get amountInCents => integer().named('amount_cents')();
  TextColumn get currencyCode => text().named('currency_code').withLength(min: 3, max: 3)();
  TextColumn get type => text().withLength(min: 6, max: 7)(); // income / expense
  TextColumn get recurrenceType => text().named('recurrence_type').withLength(min: 5, max: 7)(); // daily, weekly, monthly, yearly
  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get endDate => dateTime().named('end_date').nullable()();
  TextColumn get categoryId => text().named('category_id').nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get lastGenerated => dateTime().named('last_generated').nullable()();
  DateTimeColumn get nextOccurrence => dateTime().named('next_occurrence').nullable()();
  BoolColumn get isDeleted => boolean().named('is_deleted').withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Период бюджета
enum BudgetPeriod {
  weekly,   // Недельный бюджет
  monthly,  // Месячный бюджет
  yearly,   // Годовой бюджет
}

/// Таблица бюджетов
@DataClassName('BudgetRow')
class BudgetsTable extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 128)(); // Название бюджета
  IntColumn get limitInCents => integer().named('limit_cents')(); // Лимит в копейках
  TextColumn get currencyCode => text().named('currency_code').withLength(min: 3, max: 3)();
  TextColumn get period => text().withLength(min: 5, max: 7)(); // weekly, monthly, yearly
  TextColumn get categoryId => text().named('category_id').nullable()(); // Если null - общий бюджет
  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();
  IntColumn get warningPercent => integer().named('warning_percent').withDefault(const Constant(80))(); // Процент для предупреждения
  BoolColumn get notificationsEnabled => boolean().named('notifications_enabled').withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().named('is_deleted').withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Таблица правил автокатегоризации
/// Когда в названии транзакции встречается keyword, автоматически присваивается categoryId
@DataClassName('CategoryRuleRow')
class CategoryRulesTable extends Table {
  @override
  String get tableName => 'category_rules';

  TextColumn get id => text()();
  TextColumn get keyword => text().withLength(min: 1, max: 128)(); // Ключевое слово (например: "Magnum", "Glovo")
  TextColumn get categoryId => text().named('category_id')(); // ID категории для присвоения
  IntColumn get priority => integer().withDefault(const Constant(0))(); // Приоритет (больше = выше приоритет)
  BoolColumn get caseSensitive => boolean().named('case_sensitive').withDefault(const Constant(false))(); // Учитывать регистр
  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();
  IntColumn get matchCount => integer().named('match_count').withDefault(const Constant(0))(); // Счётчик срабатываний
  DateTimeColumn get lastUsedAt => dateTime().named('last_used_at').nullable()(); // Последнее использование
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Таблица долгов
@DataClassName('DebtRow')
class DebtsTable extends Table {
  @override
  String get tableName => 'debts';

  TextColumn get id => text()();
  TextColumn get personName => text().named('person_name').withLength(min: 1, max: 128)(); // Имя человека
  IntColumn get totalAmountInCents => integer().named('total_amount_cents')(); // Общая сумма долга в копейках
  IntColumn get repaidAmountInCents => integer().named('repaid_amount_cents').withDefault(const Constant(0))(); // Сколько уже возвращено
  TextColumn get currencyCode => text().named('currency_code').withLength(min: 3, max: 3)();
  TextColumn get type => text().withLength(min: 4, max: 6)(); // "iOwe" или "theyOwe"
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime().named('due_date').nullable()(); // Дата возврата (опционально)
  BoolColumn get isClosed => boolean().named('is_closed').withDefault(const Constant(false))(); // Закрыт ли долг
  TextColumn get comment => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  BoolColumn get isDeleted => boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Обратная связь по инсайтам (полезно / не полезно).
@DataClassName('InsightFeedbackRow')
class InsightFeedbackTable extends Table {
  @override
  String get tableName => 'insight_feedback';

  TextColumn get id => text()();
  TextColumn get fingerprint => text()();
  BoolColumn get useful => boolean()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

