import 'dart:math' as math;

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
  final cleaned = sanitizeTitleForMatch(text.trim());
  var keyword = cleaned.isEmpty ? text.trim() : cleaned;
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

/// Нижняя граница рейтинга схожести: ниже — не предлагаем категорию (fuzzy / history fuzzy).
const double kMinCategorizationRating = 0.5;

/// Порог для fuzzy-правил (после санитизации и combined rating).
const double kFuzzyRuleMinSimilarity = 0.5;

/// Порог похожести заметок при голосовании по истории.
const double kHistoryFuzzyMinSimilarity = 0.5;

/// Допуск по score: кандидаты в «ничью» попадают в разрешение по частоте истории.
const double kFuzzyScoreTieEpsilon = 0.08;

/// Пайплайн: санитизация → точные правила → fuzzy (+ частота) → история.
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
    final trimmed = rawNote.trim();
    if (trimmed.isEmpty) {
      return CategorizationResult.empty;
    }

    final sanitized = sanitizeTitleForMatch(trimmed);
    final working = sanitized.isEmpty ? trimmed : sanitized;

    final matcher = CategoryRuleMatcher(rules);
    final exactRule = matcher.findMatchingRule(working);
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

    final fuzzyRule = _bestFuzzyRule(working);
    if (fuzzyRule != null) {
      final id = fuzzyRule.rule.categoryId;
      final cat = _categoryById(id);
      if (cat != null && cat.kind == _expectedKind) {
        final confidence = (kMinCategorizationRating +
                fuzzyRule.score * (1.0 - kMinCategorizationRating))
            .clamp(kMinCategorizationRating, 0.94);
        return CategorizationResult(
          categoryId: id,
          category: cat,
          confidence: confidence,
          source: CategorizationSource.fuzzyRule,
          matchedRule: fuzzyRule.rule,
        );
      }
    }

    final workLow = working.toLowerCase();
    final exactHistoryCandidates = history
        .where((e) => !e.isDeleted && e.type == type)
        .where((e) => e.categoryId != null)
        .where((e) {
          final raw = e.note?.trim();
          if (raw == null) return false;
          final sn = sanitizeTitleForMatch(raw);
          final histKey = (sn.isEmpty ? raw : sn).toLowerCase();
          return histKey == workLow;
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

    final fuzzyHistory = _bestCategoryFromFuzzyHistory(working);
    if (fuzzyHistory != null) {
      final id = fuzzyHistory.categoryId;
      final cat = _categoryById(id);
      if (cat != null && cat.kind == _expectedKind) {
        final adjusted = math
            .max(
              kMinCategorizationRating,
              fuzzyHistory.confidence * fuzzyHistory.maxSimilarity,
            )
            .clamp(kMinCategorizationRating, 0.88);
        return CategorizationResult(
          categoryId: id,
          category: cat,
          confidence: adjusted,
          source: CategorizationSource.historyFuzzy,
        );
      }
    }

    return CategorizationResult.empty;
  }

  _FuzzyRuleHit? _bestFuzzyRule(String noteWorking) {
    final candidates = <({CategoryRule rule, double score})>[];
    final noteLow = noteWorking.toLowerCase();

    for (final rule in rules) {
      if (!rule.isActive) continue;
      if (rule.matches(noteWorking)) continue;

      final kw = rule.caseSensitive ? rule.keyword : rule.keyword.toLowerCase();
      final text = rule.caseSensitive ? noteWorking : noteLow;
      final score = bestTokenToKeywordSimilarity(text, kw);
      if (score < kMinCategorizationRating) continue;
      if (score < kFuzzyRuleMinSimilarity) continue;
      candidates.add((rule: rule, score: score));
    }

    if (candidates.isEmpty) return null;

    final maxScore = candidates.map((c) => c.score).reduce(math.max);
    final nearTop = candidates
        .where((c) => c.score >= maxScore - kFuzzyScoreTieEpsilon)
        .toList();

    if (nearTop.length == 1) {
      final c = nearTop.single;
      return _FuzzyRuleHit(rule: c.rule, score: c.score);
    }

    final byCategory = <String, List<({CategoryRule rule, double score})>>{};
    for (final c in nearTop) {
      byCategory.putIfAbsent(c.rule.categoryId, () => []).add(c);
    }

    CategoryRule? bestRule;
    var bestFreq = -1;
    var bestScorePick = 0.0;
    var bestPriority = -999999;

    for (final entry in byCategory.entries) {
      final catId = entry.key;
      final list = entry.value;
      final freq = _historyMatchFrequency(catId, noteLow);
      final bestInList = list.reduce((a, b) {
        if (a.score > b.score) return a;
        if (b.score > a.score) return b;
        return a.rule.priority >= b.rule.priority ? a : b;
      });
      if (freq > bestFreq ||
          (freq == bestFreq && bestInList.score > bestScorePick) ||
          (freq == bestFreq &&
              bestInList.score == bestScorePick &&
              bestInList.rule.priority > bestPriority)) {
        bestFreq = freq;
        bestScorePick = bestInList.score;
        bestPriority = bestInList.rule.priority;
        bestRule = bestInList.rule;
      }
    }

    if (bestRule == null) return null;
    return _FuzzyRuleHit(rule: bestRule, score: maxScore);
  }

  int _historyMatchFrequency(String categoryId, String noteWorkingLower) {
    var n = 0;
    for (final e in history) {
      if (e.isDeleted || e.type != type) continue;
      if (e.categoryId != categoryId) continue;
      final raw = e.note?.trim();
      if (raw == null || raw.isEmpty) continue;
      final sn = sanitizeTitleForMatch(raw);
      final histSide = (sn.isEmpty ? raw : sn).toLowerCase();
      if (maxTokenCrossSimilarity(noteWorkingLower, histSide) >=
          kHistoryFuzzyMinSimilarity) {
        n++;
      }
    }
    return n;
  }

  _HistoryFuzzyHit? _bestCategoryFromFuzzyHistory(String noteWorking) {
    final noteLow = noteWorking.toLowerCase();
    final perCategory = <String, ({int count, double maxSim})>{};

    for (final e in history) {
      if (e.isDeleted || e.type != type) continue;
      final cid = e.categoryId;
      if (cid == null) continue;
      final raw = e.note?.trim();
      if (raw == null || raw.isEmpty) continue;
      final sn = sanitizeTitleForMatch(raw);
      final histSide = (sn.isEmpty ? raw : sn).toLowerCase();
      final sim = maxTokenCrossSimilarity(noteLow, histSide);
      if (sim < kHistoryFuzzyMinSimilarity) continue;
      if (sim < kMinCategorizationRating) continue;

      final prev = perCategory[cid];
      if (prev == null) {
        perCategory[cid] = (count: 1, maxSim: sim);
      } else {
        perCategory[cid] = (
          count: prev.count + 1,
          maxSim: sim > prev.maxSim ? sim : prev.maxSim,
        );
      }
    }

    if (perCategory.isEmpty) return null;

    String? bestId;
    var bestCount = 0;
    var bestSim = 0.0;
    perCategory.forEach((id, v) {
      if (v.count > bestCount ||
          (v.count == bestCount && v.maxSim > bestSim)) {
        bestCount = v.count;
        bestSim = v.maxSim;
        bestId = id;
      }
    });

    if (bestId == null) return null;

    final confidence = bestCount >= 3
        ? 0.78
        : bestCount >= 2
            ? 0.68
            : 0.58;

    return _HistoryFuzzyHit(
      categoryId: bestId!,
      confidence: confidence,
      maxSimilarity: bestSim,
    );
  }
}

class _FuzzyRuleHit {
  _FuzzyRuleHit({required this.rule, required this.score});

  final CategoryRule rule;
  final double score;
}

class _HistoryFuzzyHit {
  _HistoryFuzzyHit({
    required this.categoryId,
    required this.confidence,
    required this.maxSimilarity,
  });

  final String categoryId;
  final double confidence;
  final double maxSimilarity;
}
