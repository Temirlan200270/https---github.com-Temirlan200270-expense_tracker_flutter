import 'category.dart';
import 'category_rule.dart';
import 'expense.dart';
import 'string_similarity.dart';

/// Источник подсказки категории: правила → fuzzy-правила → история → нет.
enum CategorizationSource {
  /// Сработало явное правило (подстрока / contains).
  rule,

  /// Совпало правило по нечёткой схожести (опечатки, вариации названия).
  fuzzyRule,

  /// Точное совпадение заметки с прошлой транзакцией того же типа.
  history,

  /// Доминирующая категория среди похожих заметок в истории.
  historyFuzzy,

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

/// Пороги Matching Engine (правила / история).
/// Для коротких слов одна опечатка даёт ~0.83 (6 букв) — 0.82 ловит «Magnun»↔«Magnum».
const double kFuzzyRuleMinSimilarity = 0.82;
const double kHistoryFuzzyMinSimilarity = 0.82;

/// Пайплайн: точные правила → fuzzy-правила → точная история → частотная похожая история.
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

  /// Категоризация по тексту заметки / названия транзакции.
  CategorizationResult categorize(String rawNote) {
    final note = rawNote.trim();
    if (note.isEmpty) {
      return CategorizationResult.empty;
    }

    final matcher = CategoryRuleMatcher(rules);
    final exactRule = matcher.findMatchingRule(note);
    if (exactRule != null) {
      final id = exactRule.categoryId;
      final cat = _categoryById(id);
      if (cat != null && cat.kind != _expectedKind) {
        return CategorizationResult.empty;
      }
      if (cat != null) {
        return CategorizationResult(
          categoryId: id,
          category: cat,
          confidence: 1.0,
          source: CategorizationSource.rule,
          matchedRule: exactRule,
        );
      }
    }

    final fuzzyRule = _bestFuzzyRule(note);
    if (fuzzyRule != null) {
      final id = fuzzyRule.rule.categoryId;
      final cat = _categoryById(id);
      if (cat != null && cat.kind == _expectedKind) {
        final confidence = (0.52 + fuzzyRule.score * 0.42).clamp(0.55, 0.94);
        return CategorizationResult(
          categoryId: id,
          category: cat,
          confidence: confidence,
          source: CategorizationSource.fuzzyRule,
          matchedRule: fuzzyRule.rule,
        );
      }
    }

    final normalized = note.toLowerCase();
    final exactHistoryCandidates = history
        .where((e) => !e.isDeleted && e.type == type)
        .where((e) => e.categoryId != null)
        .where((e) {
          final n = e.note?.trim().toLowerCase();
          return n != null && n == normalized;
        })
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    if (exactHistoryCandidates.isNotEmpty) {
      final mostRecent = exactHistoryCandidates.first;
      final id = mostRecent.categoryId;
      final cat = _categoryById(id);
      if (cat != null && cat.kind == _expectedKind) {
        final sameCategoryCount =
            exactHistoryCandidates.where((e) => e.categoryId == id).length;
        final confidence = sameCategoryCount >= 2 ? 0.9 : 0.75;
        return CategorizationResult(
          categoryId: id,
          category: cat,
          confidence: confidence,
          source: CategorizationSource.history,
        );
      }
    }

    final fuzzyHistory = _bestCategoryFromFuzzyHistory(note);
    if (fuzzyHistory != null) {
      final id = fuzzyHistory.categoryId;
      final cat = _categoryById(id);
      if (cat != null && cat.kind == _expectedKind) {
        return CategorizationResult(
          categoryId: id,
          category: cat,
          confidence: fuzzyHistory.confidence,
          source: CategorizationSource.historyFuzzy,
        );
      }
    }

    return CategorizationResult.empty;
  }

  _FuzzyRuleHit? _bestFuzzyRule(String note) {
    CategoryRule? bestRule;
    var bestScore = 0.0;

    for (final rule in rules) {
      if (!rule.isActive) continue;
      if (rule.matches(note)) continue;

      final kw = rule.caseSensitive ? rule.keyword : rule.keyword.toLowerCase();
      final text = rule.caseSensitive ? note : note.toLowerCase();
      final score = bestTokenToKeywordSimilarity(text, kw);
      if (score < kFuzzyRuleMinSimilarity) continue;

      if (score > bestScore ||
          (score == bestScore &&
              bestRule != null &&
              rule.priority > bestRule.priority)) {
        bestScore = score;
        bestRule = rule;
      }
    }

    if (bestRule == null) return null;
    return _FuzzyRuleHit(rule: bestRule, score: bestScore);
  }

  _HistoryFuzzyHit? _bestCategoryFromFuzzyHistory(String note) {
    final counts = <String, int>{};

    for (final e in history) {
      if (e.isDeleted || e.type != type) continue;
      final cid = e.categoryId;
      if (cid == null) continue;
      final n = e.note?.trim();
      if (n == null || n.isEmpty) continue;

      if (maxTokenCrossSimilarity(note, n) >= kHistoryFuzzyMinSimilarity) {
        counts[cid] = (counts[cid] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return null;

    var bestId = '';
    var bestCount = 0;
    counts.forEach((id, c) {
      if (c > bestCount) {
        bestCount = c;
        bestId = id;
      }
    });

    final confidence = bestCount >= 3
        ? 0.78
        : bestCount >= 2
            ? 0.68
            : 0.58;

    return _HistoryFuzzyHit(categoryId: bestId, confidence: confidence);
  }
}

class _FuzzyRuleHit {
  _FuzzyRuleHit({required this.rule, required this.score});

  final CategoryRule rule;
  final double score;
}

class _HistoryFuzzyHit {
  _HistoryFuzzyHit({required this.categoryId, required this.confidence});

  final String categoryId;
  final double confidence;
}
