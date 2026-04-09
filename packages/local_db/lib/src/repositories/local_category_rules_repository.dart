import 'package:drift/drift.dart';
import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

import '../database/app_database.dart';

/// Локальная реализация репозитория правил автокатегоризации
class LocalCategoryRulesRepository implements CategoryRulesRepository {
  LocalCategoryRulesRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<CategoryRule>> watchRules() {
    final query = _db.select(_db.categoryRulesTable)
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.priority)]);

    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<List<CategoryRule>> fetchRules() async {
    final query = _db.select(_db.categoryRulesTable)
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.priority)]);

    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<CategoryRule?> getRule(String id) async {
    final query = _db.select(_db.categoryRulesTable)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();
    return row != null ? _mapRow(row) : null;
  }

  @override
  Future<List<CategoryRule>> getRulesByCategory(String categoryId) async {
    final query = _db.select(_db.categoryRulesTable)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.priority)]);

    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<CategoryRule?> findRuleByKeyword(String keyword) async {
    final query = _db.select(_db.categoryRulesTable)
      ..where((tbl) => tbl.keyword.equals(keyword.toLowerCase()))
      ..where((tbl) => tbl.isActive.equals(true));

    final row = await query.getSingleOrNull();
    return row != null ? _mapRow(row) : null;
  }

  @override
  Future<void> upsertRule(CategoryRule rule) async {
    await _db.into(_db.categoryRulesTable).insertOnConflictUpdate(
          CategoryRulesTableCompanion(
            id: Value(rule.id),
            keyword: Value(rule.keyword.toLowerCase()), // Нормализуем keyword
            categoryId: Value(rule.categoryId),
            priority: Value(rule.priority),
            caseSensitive: Value(rule.caseSensitive),
            isActive: Value(rule.isActive),
            matchCount: Value(rule.matchCount),
            lastUsedAt: Value(rule.lastUsedAt),
            createdAt: Value(rule.createdAt),
            updatedAt: Value(rule.updatedAt ?? DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Future<void> deleteRule(String id) async {
    await (_db.delete(_db.categoryRulesTable)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> incrementMatchCount(String id) async {
    final rule = await getRule(id);
    if (rule != null) {
      await upsertRule(rule.incrementMatchCount());
    }
  }

  @override
  Future<CategoryRuleMatcher> getMatcher() async {
    final rules = await fetchRules();
    return CategoryRuleMatcher(rules);
  }

  CategoryRule _mapRow(CategoryRuleRow row) {
    return CategoryRule(
      id: row.id,
      keyword: row.keyword,
      categoryId: row.categoryId,
      priority: row.priority,
      caseSensitive: row.caseSensitive,
      isActive: row.isActive,
      matchCount: row.matchCount,
      lastUsedAt: row.lastUsedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

