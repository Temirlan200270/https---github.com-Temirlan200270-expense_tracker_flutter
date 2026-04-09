import 'dart:math' as math;

import 'categorization.dart';
import 'expense.dart';

/// Порог: ниже — строка попадёт в «проверить» на экране review.
const double kPendingImportLowConfidence = 0.7;

/// Порог: при автосохранении без review подставляем категорию только если не ниже.
const double kPendingImportAutoApplyMinConfidence = 0.5;

/// Порог «нужно внимание» для группировки и дефолтного включения в импорт.
const double kPendingImportNeedsAttentionConfidence = 0.75;

/// Черновик строки импорта с результатом Matching Engine (до записи в БД / review).
class PendingImportExpense {
  PendingImportExpense({
    required this.parsed,
    this.predictedCategoryId,
    required this.confidence,
    required this.predictionSource,
    this.isIncluded = true,
    String? effectiveCategoryId,
    bool resolveEffectiveFromPrediction = true,
  }) : effectiveCategoryId = resolveEffectiveFromPrediction
            ? (effectiveCategoryId ??
                _defaultEffectiveCategory(predictedCategoryId, confidence))
            : effectiveCategoryId;

  /// Распарсенная трата (как из CSV/PDF).
  final Expense parsed;

  /// Категория с пайплайна (может быть null).
  final String? predictedCategoryId;

  /// Уверенность [0, 1] из [CategorizationResult].
  final double confidence;

  /// Откуда взята подсказка (правило / fuzzy / история).
  final CategorizationSource predictionSource;

  /// Участвует ли строка в финальном импорте (снять для мусора).
  bool isIncluded;

  /// Категория, которая уйдёт в БД; на review пользователь сможет менять.
  String? effectiveCategoryId;

  static String? _defaultEffectiveCategory(String? pred, double conf) {
    if (pred == null || pred.isEmpty) return null;
    if (conf < kPendingImportAutoApplyMinConfidence) return null;
    return pred;
  }

  /// Строки без категории или с низкой уверенностью — вверху review и по умолчанию выкл.
  bool get needsAttention =>
      confidence < kPendingImportNeedsAttentionConfidence ||
      effectiveCategoryId == null;

  /// Дефолт чекбокса: «уверенные» с категорией — вкл., остальное — выкл.
  bool get defaultIsIncludedForReview => !needsAttention;

  /// Нужна ручная проверка на экране review (узкий порог по категории).
  bool get isLowConfidence =>
      predictedCategoryId != null && confidence < kPendingImportLowConfidence;

  /// Можно считать «авто-подтверждённой» для bulk «ОК».
  bool get isHighConfidence =>
      predictedCategoryId != null && confidence >= 0.9;

  /// Полная копия с правками. [specifyEffectiveCategoryId]: true — задать категорию,
  /// в том числе `null` (сброс).
  PendingImportExpense copyWith({
    Expense? parsed,
    String? predictedCategoryId,
    double? confidence,
    CategorizationSource? predictionSource,
    bool? isIncluded,
    String? effectiveCategoryId,
    bool specifyEffectiveCategoryId = false,
  }) {
    final String? eff = specifyEffectiveCategoryId
        ? effectiveCategoryId
        : (effectiveCategoryId ?? this.effectiveCategoryId);
    return PendingImportExpense(
      parsed: parsed ?? this.parsed,
      predictedCategoryId: predictedCategoryId ?? this.predictedCategoryId,
      confidence: confidence ?? this.confidence,
      predictionSource: predictionSource ?? this.predictionSource,
      isIncluded: isIncluded ?? this.isIncluded,
      effectiveCategoryId: eff,
      resolveEffectiveFromPrediction: false,
    );
  }

  /// Сборка сущности для upsert в репозиторий.
  Expense toExpenseForSave() {
    if (effectiveCategoryId != null) {
      return parsed.copyWith(categoryId: effectiveCategoryId);
    }
    return parsed;
  }

  /// Копия с изменённой эффективной категорией (для inline-редактирования).
  PendingImportExpense copyWithEffectiveCategory(String? categoryId) {
    return copyWith(
      specifyEffectiveCategoryId: true,
      effectiveCategoryId: categoryId,
    );
  }
}

/// Приоритет для сортировки: выше — важнее показать первым (дорогие + неуверенные).
double importReviewPriority(
  PendingImportExpense e, {
  required int maxAmountCents,
}) {
  final confTerm = (1.0 - e.confidence.clamp(0.0, 1.0)) * 0.6;
  final catTerm = e.effectiveCategoryId == null ? 0.3 : 0.0;
  final absCents = e.parsed.amount.amountInCents.abs();
  final denom = maxAmountCents <= 0 ? 1 : maxAmountCents;
  final norm = (absCents / denom).clamp(0.0, 1.0);
  return confTerm + catTerm + norm * 0.1;
}

/// Сортировка для review по приоритету (убывание), затем по сумме и дате.
void sortPendingImportsByReviewPriority(List<PendingImportExpense> list) {
  if (list.isEmpty) return;
  final maxCents = list.fold<int>(
    1,
    (m, e) => math.max(m, e.parsed.amount.amountInCents.abs()),
  );
  list.sort((a, b) {
    final pa = importReviewPriority(a, maxAmountCents: maxCents);
    final pb = importReviewPriority(b, maxAmountCents: maxCents);
    final byP = pb.compareTo(pa);
    if (byP != 0) return byP;
    final byAmount = b.parsed.amount.amountInCents.abs().compareTo(
          a.parsed.amount.amountInCents.abs(),
        );
    if (byAmount != 0) return byAmount;
    return a.parsed.occurredAt.compareTo(b.parsed.occurredAt);
  });
}

/// Сортировка для review (совместимость): делегирует приоритетной сортировке.
List<PendingImportExpense> sortPendingImportsForReview(
  List<PendingImportExpense> list,
) {
  final copy = List<PendingImportExpense>.from(list);
  sortPendingImportsByReviewPriority(copy);
  return copy;
}
