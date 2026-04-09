import 'package:drift/drift.dart';
import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

import '../database/app_database.dart';

/// Временная реализация репозитория с использованием raw SQL
/// После запуска build_runner можно будет использовать типизированные запросы
class LocalRecurringExpensesRepository implements RecurringExpensesRepository {
  LocalRecurringExpensesRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<RecurringExpense>> fetchAll({bool includeInactive = false}) async {
    final query = '''
      SELECT * FROM recurring_expenses 
      WHERE is_deleted = 0
      ${includeInactive ? '' : 'AND is_active = 1'}
      ORDER BY next_occurrence ASC
    ''';
    final rows = await _db.customSelect(query).get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<RecurringExpense?> getRecurringExpense(String id) async {
    final query = '''
      SELECT * FROM recurring_expenses 
      WHERE id = ? AND is_deleted = 0
    ''';
    final rows = await _db.customSelect(
      query,
      variables: [Variable<String>(id)],
    ).get();
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<List<RecurringExpense>> fetchDueRecurringExpenses() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final query = '''
      SELECT * FROM recurring_expenses 
      WHERE is_deleted = 0 
        AND is_active = 1 
        AND (next_occurrence IS NULL OR next_occurrence <= ?)
      ORDER BY next_occurrence ASC
    ''';
    final rows = await _db.customSelect(
      query,
      variables: [Variable<int>(now)],
    ).get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<void> upsert(RecurringExpense recurringExpense) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final endDateMs = recurringExpense.endDate?.millisecondsSinceEpoch;
    final categoryId = recurringExpense.categoryId;
    final note = recurringExpense.note;
    final lastGeneratedMs = recurringExpense.lastGenerated?.millisecondsSinceEpoch;
    final nextOccurrenceMs = recurringExpense.nextOccurrence?.millisecondsSinceEpoch;
    final deletedAtMs = recurringExpense.deletedAt?.millisecondsSinceEpoch;
    final updatedAtMs = recurringExpense.updatedAt?.millisecondsSinceEpoch ?? now;
    
    final query = '''
      INSERT INTO recurring_expenses (
        id, name, amount_cents, currency_code, type, recurrence_type,
        start_date, end_date, category_id, note, is_active,
        last_generated, next_occurrence, is_deleted, deleted_at,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        amount_cents = excluded.amount_cents,
        currency_code = excluded.currency_code,
        type = excluded.type,
        recurrence_type = excluded.recurrence_type,
        start_date = excluded.start_date,
        end_date = excluded.end_date,
        category_id = excluded.category_id,
        note = excluded.note,
        is_active = excluded.is_active,
        last_generated = excluded.last_generated,
        next_occurrence = excluded.next_occurrence,
        is_deleted = excluded.is_deleted,
        deleted_at = excluded.deleted_at,
        updated_at = excluded.updated_at
    ''';
    
    await _db.customStatement(
      query,
      [
        recurringExpense.id,
        recurringExpense.name,
        recurringExpense.amount.amountInCents,
        recurringExpense.amount.currencyCode,
        recurringExpense.type.name,
        recurringExpense.recurrenceType.name,
        recurringExpense.startDate.millisecondsSinceEpoch,
        endDateMs,
        categoryId,
        note,
        recurringExpense.isActive ? 1 : 0,
        lastGeneratedMs,
        nextOccurrenceMs,
        recurringExpense.isDeleted ? 1 : 0,
        deletedAtMs,
        recurringExpense.createdAt.millisecondsSinceEpoch,
        updatedAtMs,
      ],
    );
  }

  @override
  Future<void> softDelete(String id, {DateTime? deletedAt}) async {
    final deletedAtMs = (deletedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    final updatedAtMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.customStatement(
      'UPDATE recurring_expenses SET is_deleted = 1, deleted_at = ?, updated_at = ? WHERE id = ?',
      [deletedAtMs, updatedAtMs, id],
    );
  }

  @override
  Stream<List<RecurringExpense>> watchAll({bool includeInactive = false}) {
    // Для stream используем простой подход - периодически опрашиваем
    // После генерации кода можно будет использовать watch()
    return Stream.periodic(const Duration(seconds: 1), (_) => fetchAll(includeInactive: includeInactive))
        .asyncMap((future) => future);
  }

  RecurringExpense _mapRow(QueryRow row) {
    final endDateMs = row.read<int?>('end_date');
    final lastGeneratedMs = row.read<int?>('last_generated');
    final nextOccurrenceMs = row.read<int?>('next_occurrence');
    final updatedAtMs = row.read<int?>('updated_at');
    final deletedAtMs = row.read<int?>('deleted_at');
    
    return RecurringExpense(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      amount: Money(
        amountInCents: row.read<int>('amount_cents'),
        currencyCode: row.read<String>('currency_code'),
      ),
      type: ExpenseType.values.firstWhere(
        (e) => e.name == row.read<String>('type'),
        orElse: () => ExpenseType.expense,
      ),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == row.read<String>('recurrence_type'),
        orElse: () => RecurrenceType.monthly,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(row.read<int>('start_date'), isUtc: true),
      endDate: endDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(endDateMs, isUtc: true)
          : null,
      categoryId: row.read<String?>('category_id'),
      note: row.read<String?>('note'),
      isActive: row.read<int>('is_active') == 1,
      lastGenerated: lastGeneratedMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastGeneratedMs, isUtc: true)
          : null,
      nextOccurrence: nextOccurrenceMs != null
          ? DateTime.fromMillisecondsSinceEpoch(nextOccurrenceMs, isUtc: true)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at'), isUtc: true),
      updatedAt: updatedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true)
          : null,
      deletedAt: deletedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs, isUtc: true)
          : null,
      isDeleted: row.read<int>('is_deleted') == 1,
    );
  }
}

