import 'package:drift/drift.dart';
import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

import '../database/app_database.dart';

class LocalCategoriesRepository implements CategoriesRepository {
  LocalCategoriesRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Category>> fetchAll() async {
    final rows = await (_db.select(_db.categoriesTable)..where((tbl) => tbl.isDeleted.equals(false))).get();
    return rows.map(_mapRow).toList();
  }

  @override
  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categoriesTable)..where((tbl) => tbl.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<void> upsert(Category category) async {
    await _db.into(_db.categoriesTable).insertOnConflictUpdate(
          CategoriesTableCompanion(
            id: Value(category.id),
            name: Value(category.name),
            colorValue: Value(category.colorValue),
            kind: Value(category.kind.name),
            isDeleted: Value(category.isDeleted),
            deletedAt: Value(category.deletedAt),
            createdAt: Value(category.createdAt),
            updatedAt: Value(category.updatedAt ?? DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Future<void> upsertMany(List<Category> categories) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.categoriesTable,
        categories.map(
          (category) => CategoriesTableCompanion(
            id: Value(category.id),
            name: Value(category.name),
            colorValue: Value(category.colorValue),
            kind: Value(category.kind.name),
            isDeleted: Value(category.isDeleted),
            deletedAt: Value(category.deletedAt),
            createdAt: Value(category.createdAt),
            updatedAt: Value(category.updatedAt ?? DateTime.now().toUtc()),
          ),
        ),
      );
    });
  }

  @override
  Future<void> softDelete(String id, {DateTime? deletedAt}) async {
    await (_db.update(_db.categoriesTable)..where((tbl) => tbl.id.equals(id))).write(
      CategoriesTableCompanion(
        isDeleted: Value(true),
        deletedAt: Value(deletedAt ?? DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Category _mapRow(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      colorValue: row.colorValue,
      kind: CategoryKind.values.firstWhere(
        (kind) => kind.name == row.kind,
        orElse: () => CategoryKind.expense,
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      isDeleted: row.isDeleted,
    );
  }
}

