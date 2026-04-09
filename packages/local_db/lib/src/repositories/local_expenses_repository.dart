import 'package:drift/drift.dart';
import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

import '../database/app_database.dart';

class LocalExpensesRepository implements ExpensesRepository {
  LocalExpensesRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Expense>> fetchExpenses({ExpenseFilter filter = const ExpenseFilter()}) async {
    final query = _buildQuery(filter);
    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<Expense> getExpense(String id) async {
    final row = await (_db.select(_db.expensesTable)..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapRow(row);
  }

  @override
  Future<void> softDelete(String id, {DateTime? deletedAt}) async {
    await (_db.update(_db.expensesTable)..where((tbl) => tbl.id.equals(id))).write(
      ExpensesTableCompanion(
        isDeleted: Value(true),
        deletedAt: Value(deletedAt ?? DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> softDeleteMany(List<String> ids, {DateTime? deletedAt}) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.expensesTable)
          ..where((tbl) => tbl.id.isIn(ids)))
        .write(
      ExpensesTableCompanion(
        isDeleted: Value(true),
        deletedAt: Value(deletedAt ?? DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> deleteAllExpenses() async {
    await _db.delete(_db.expensesTable).go();
  }

  @override
  Future<void> upsertExpense(Expense expense) async {
    await _db.into(_db.expensesTable).insertOnConflictUpdate(
          ExpensesTableCompanion(
            id: Value(expense.id),
            amountInCents: Value(expense.amount.amountInCents),
            currencyCode: Value(expense.amount.currencyCode),
            type: Value(expense.type.name),
            occurredAt: Value(expense.occurredAt),
            categoryId: Value(expense.categoryId),
            note: Value(expense.note),
            isDeleted: Value(expense.isDeleted),
            deletedAt: Value(expense.deletedAt),
            createdAt: Value(expense.createdAt),
            updatedAt: Value(expense.updatedAt ?? DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Stream<List<Expense>> watchExpenses({ExpenseFilter filter = const ExpenseFilter()}) {
    final query = _buildQuery(filter);
    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  SimpleSelectStatement<$ExpensesTableTable, ExpenseRow> _buildQuery(ExpenseFilter filter) {
    final query = _db.select(_db.expensesTable)
      ..where((tbl) => tbl.isDeleted.equals(false));

    if (filter.from != null) {
      query.where((tbl) => tbl.occurredAt.isBiggerOrEqualValue(filter.from!));
    }
    if (filter.to != null) {
      query.where((tbl) => tbl.occurredAt.isSmallerOrEqualValue(filter.to!));
    }
    if (filter.type != null) {
      query.where((tbl) => tbl.type.equals(filter.type!.name));
    }
    if (filter.categoryIds.isNotEmpty) {
      query.where((tbl) => tbl.categoryId.isIn(filter.categoryIds));
    }
    if (filter.searchTerm != null && filter.searchTerm!.isNotEmpty) {
      final like = '%${filter.searchTerm!.toLowerCase()}%';
      query.where(
        (tbl) => tbl.note.lower().like(like),
      );
    }

    query
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.occurredAt)])
      ..limit(filter.limit, offset: filter.offset);

    return query;
  }

  Expense _mapRow(ExpenseRow row) {
    return Expense(
      id: row.id,
      amount: Money(
        amountInCents: row.amountInCents,
        currencyCode: row.currencyCode,
      ),
      type: ExpenseType.values.firstWhere(
        (value) => value.name == row.type,
        orElse: () => ExpenseType.expense,
      ),
      occurredAt: row.occurredAt,
      categoryId: row.categoryId,
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      isDeleted: row.isDeleted,
    );
  }
}

