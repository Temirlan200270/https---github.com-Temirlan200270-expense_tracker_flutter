import 'package:drift/drift.dart';
import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

import '../database/app_database.dart';

/// Локальная реализация репозитория долгов
class LocalDebtsRepository implements DebtsRepository {
  LocalDebtsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Debt>> watchDebts() {
    final query = _db.select(_db.debtsTable)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<List<Debt>> fetchDebts() async {
    final query = _db.select(_db.debtsTable)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<Debt>> fetchDebtsByType(DebtType type) async {
    final query = _db.select(_db.debtsTable)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.type.equals(type.name))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<Debt?> getDebt(String id) async {
    final query = _db.select(_db.debtsTable)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();
    return row != null ? _mapRow(row) : null;
  }

  @override
  Future<void> upsertDebt(Debt debt) async {
    await _db.into(_db.debtsTable).insertOnConflictUpdate(
          DebtsTableCompanion(
            id: Value(debt.id),
            personName: Value(debt.personName),
            totalAmountInCents: Value(debt.totalAmount.amountInCents),
            repaidAmountInCents: Value(debt.repaidAmount.amountInCents),
            currencyCode: Value(debt.totalAmount.currencyCode),
            type: Value(debt.type.name),
            dueDate: Value(debt.dueDate),
            isClosed: Value(debt.isClosed),
            comment: Value(debt.comment),
            createdAt: Value(debt.createdAt),
            updatedAt: Value(debt.updatedAt ?? DateTime.now().toUtc()),
            deletedAt: Value(debt.deletedAt),
            isDeleted: Value(debt.isDeleted),
          ),
        );
  }

  @override
  Future<void> addRepayment(String id, Money amount) async {
    final debt = await getDebt(id);
    if (debt == null) return;

    final newRepaid = Money(
      amountInCents: debt.repaidAmount.amountInCents + amount.amountInCents,
      currencyCode: debt.repaidAmount.currencyCode,
    );

    await upsertDebt(
      debt.copyWith(
        repaidAmount: newRepaid,
        isClosed: newRepaid.amountInCents >= debt.totalAmount.amountInCents,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> softDelete(String id, {DateTime? deletedAt}) async {
    await (_db.update(_db.debtsTable)..where((tbl) => tbl.id.equals(id)))
        .write(
      DebtsTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(deletedAt ?? DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Debt _mapRow(DebtRow row) {
    return Debt(
      id: row.id,
      personName: row.personName,
      totalAmount: Money(
        amountInCents: row.totalAmountInCents,
        currencyCode: row.currencyCode,
      ),
      repaidAmount: Money(
        amountInCents: row.repaidAmountInCents,
        currencyCode: row.currencyCode,
      ),
      type: DebtType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => DebtType.theyOwe,
      ),
      dueDate: row.dueDate,
      isClosed: row.isClosed,
      comment: row.comment,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      isDeleted: row.isDeleted,
    );
  }
}

