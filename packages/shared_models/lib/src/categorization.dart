import 'category.dart';
import 'category_rule.dart';
import 'expense.dart';

/// Источник подсказки категории (минимальный pipeline: правила → история → нет).
enum CategorizationSource {
  /// Сработало явное правило по ключевому слову.
  rule,

  /// Совпала заметка с прошлой транзакцией того же типа.
  history,

  /// Подсказки нет.
  none,
}

/// Результат шага категоризации с уверенностью для UI и обучения.
class CategorizationResult {
  const CategorizationResult({
    this.categoryId,
    this.category,
    required this.confidence,
    required this.source,
    this.matchedRule,
  });

  /// Пустой результат (нет категории, уверенность 0).
  static const CategorizationResult empty = CategorizationResult(
    confidence: 0,
    source: CategorizationSource.none,
  );

  final String? categoryId;
  final Category? category;
  final double confidence;
  final CategorizationSource source;
  final CategoryRule? matchedRule;
}

/// Нормализует текст заметки в ключевое слово для правила (общая логика с [CategoryRulesController]).
String extractKeywordFromNote(String text) {
  var keyword = text.trim();
  if (keyword.contains(',')) {
    keyword = keyword.split(',').first.trim();
  }
  if (keyword.contains(';')) {
    keyword = keyword.split(';').first.trim();
  }
  if (keyword.length > 50) {
    keyword = keyword.substring(0, 50);
  }
  return keyword;
}

/// Минимальный pipeline: правила → точное совпадение заметки в истории → иначе пусто.
class TransactionCategorizationPipeline {
  TransactionCategorizationPipeline({
    required this.rules,
    required this.history,
    required this.categories,
    required this.type,
  });

  final List<CategoryRule> rules;
  final List<Expense> history;
  final List<Category> categories;
  final ExpenseType type;

  CategoryKind get _expectedKind =>
      type.isIncome ? CategoryKind.income : CategoryKind.expense;

  Category? _categoryById(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id && !c.isDeleted) return c;
    }
    return null;
  }

  /// Категоризация по тексту заметки (без fuzzy и сложной нормализации).
  CategorizationResult categorize(String rawNote) {
    final note = rawNote.trim();
    if (note.isEmpty) {
      return CategorizationResult.empty;
    }

    final matcher = CategoryRuleMatcher(rules);
    final matchedRule = matcher.findMatchingRule(note);
    if (matchedRule != null) {
      final id = matchedRule.categoryId;
      final cat = _categoryById(id);
      if (cat != null && cat.kind != _expectedKind) {
        return CategorizationResult.empty;
      }
      return CategorizationResult(
        categoryId: id,
        category: cat,
        confidence: 1.0,
        source: CategorizationSource.rule,
        matchedRule: matchedRule,
      );
    }

    final normalized = note.toLowerCase();
    final candidates = history
        .where((e) => !e.isDeleted && e.type == type)
        .where((e) => e.categoryId != null)
        .where((e) {
          final n = e.note?.trim().toLowerCase();
          return n != null && n == normalized;
        })
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    if (candidates.isEmpty) {
      return CategorizationResult.empty;
    }

    final mostRecent = candidates.first;
    final id = mostRecent.categoryId;
    final cat = _categoryById(id);
    if (cat == null || cat.kind != _expectedKind) {
      return CategorizationResult.empty;
    }

    final sameCategoryCount =
        candidates.where((e) => e.categoryId == id).length;
    final confidence = sameCategoryCount >= 2 ? 0.9 : 0.75;

    return CategorizationResult(
      categoryId: id,
      category: cat,
      confidence: confidence,
      source: CategorizationSource.history,
    );
  }
}
