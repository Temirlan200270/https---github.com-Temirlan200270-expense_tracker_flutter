import 'package:drift/drift.dart';
import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

import '../database/app_database.dart';

class LocalRecurringExpensesRepository implements RecurringExpensesRepository {
  LocalRecurringExpensesRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<RecurringExpense>> fetchAll({bool includeInactive = false}) async {
    final query = _db.select(_db.recurringExpensesTable)
      ..where((tbl) => tbl.isDeleted.equals(false));
    
    if (!includeInactive) {
      query.where((tbl) => tbl.isActive.equals(true));
    }
    
    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<RecurringExpense?> getRecurringExpense(String id) async {
    final row = await (_db.select(_db.recurringExpensesTable)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapRow(row);
  }

  @override
  Future<List<RecurringExpense>> fetchDueRecurringExpenses() async {
    final now = DateTime.now();
    final rows = await (_db.select(_db.recurringExpensesTable)
          ..where((tbl) => 
              tbl.isDeleted.equals(false) &
              tbl.isActive.equals(true) &
              tbl.nextOccurrence.isSmallerOrEqualValue(now)))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<void> upsert(RecurringExpense recurringExpense) async {
    await _db.into(_db.recurringExpensesTable).insertOnConflictUpdate(
      RecurringExpensesTableCompanion(
        id: Value(recurringExpense.id),
        name: Value(recurringExpense.name),
        amountInCents: Value(recurringExpense.amount.amountInCents),
        currencyCode: Value(recurringExpense.amount.currencyCode),
        type: Value(recurringExpense.type.name),
        recurrenceType: Value(recurringExpense.recurrenceType.name),
        startDate: Value(recurringExpense.startDate),
        endDate: Value(recurringExpense.endDate),
        categoryId: Value(recurringExpense.categoryId),
        note: Value(recurringExpense.note),
        isActive: Value(recurringExpense.isActive),
        lastGenerated: Value(recurringExpense.lastGenerated),
        nextOccurrence: Value(recurringExpense.nextOccurrence),
        isDeleted: Value(recurringExpense.isDeleted),
        deletedAt: Value(recurringExpense.deletedAt),
        createdAt: Value(recurringExpense.createdAt),
        updatedAt: Value(recurringExpense.updatedAt ?? DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> softDelete(String id, {DateTime? deletedAt}) async {
    await (_db.update(_db.recurringExpensesTable)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      RecurringExpensesTableCompanion(
        isDeleted: Value(true),
        deletedAt: Value(deletedAt ?? DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Stream<List<RecurringExpense>> watchAll({bool includeInactive = false}) {
    final query = _db.select(_db.recurringExpensesTable)
      ..where((tbl) => tbl.isDeleted.equals(false));
    
    if (!includeInactive) {
      query.where((tbl) => tbl.isActive.equals(true));
    }
    
    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  RecurringExpense _mapRow(RecurringExpenseRow row) {
    return RecurringExpense(
      id: row.id,
      name: row.name,
      amount: Money(
        amountInCents: row.amountInCents,
        currencyCode: row.currencyCode,
      ),
      type: ExpenseType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => ExpenseType.expense,
      ),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == row.recurrenceType,
        orElse: () => RecurrenceType.monthly,
      ),
      startDate: row.startDate,
      endDate: row.endDate,
      categoryId: row.categoryId,
      note: row.note,
      isActive: row.isActive,
      lastGenerated: row.lastGenerated,
      nextOccurrence: row.nextOccurrence,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      isDeleted: row.isDeleted,
    );
  }
}

