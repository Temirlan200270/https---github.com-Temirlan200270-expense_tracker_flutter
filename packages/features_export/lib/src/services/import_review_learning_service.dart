import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

/// Замыкание цикла обучения: правила из явных правок на экране review импорта.
///
/// Ключ — [extractKeywordFromNote] (как в [CategoryRulesController]), чтобы совпадать
/// с ручным созданием правил из формы траты.
class ImportReviewLearningService {
  ImportReviewLearningService(this._rules);

  final CategoryRulesRepository _rules;

  /// Правила для строк, где итоговая категория отличается от предсказания пайплайна
  /// (включая случай «предсказания не было»).
  ///
  /// Дубликаты по ключу в одном батче схлопываются (последняя категория побеждает).
  /// Возвращает число выполненных upsert-ов.
  Future<int> learnFromReviewSnapshot(List<PendingImportExpense> snapshot) async {
    final dedupe = <String, String>{};

    for (final item in snapshot) {
      if (!item.isIncluded) continue;
      final categoryId = item.effectiveCategoryId;
      if (categoryId == null) continue;

      final predicted = item.predictedCategoryId;
      if (predicted == categoryId) {
        continue;
      }

      final note = item.parsed.note ?? '';
      final keyword = extractKeywordFromNote(note).trim();
      if (keyword.isEmpty) continue;

      final key = keyword.toLowerCase();
      dedupe[key] = categoryId;
    }

    var upserts = 0;
    for (final e in dedupe.entries) {
      await _upsertLearned(keywordLower: e.key, categoryId: e.value);
      upserts++;
    }
    return upserts;
  }

  Future<void> _upsertLearned({
    required String keywordLower,
    required String categoryId,
  }) async {
    final existing = await _rules.findRuleByKeyword(keywordLower);
    final now = DateTime.now().toUtc();

    if (existing != null) {
      if (existing.categoryId == categoryId) {
        await _rules.upsertRule(
          existing.copyWith(
            priority: (existing.priority + 1).clamp(0, 100),
            updatedAt: now,
          ),
        );
      } else {
        await _rules.upsertRule(
          existing.copyWith(
            categoryId: categoryId,
            updatedAt: now,
          ),
        );
      }
      return;
    }

    await _rules.upsertRule(
      CategoryRule(
        keyword: keywordLower,
        categoryId: categoryId,
        priority: 15,
        caseSensitive: false,
      ),
    );
  }
}
