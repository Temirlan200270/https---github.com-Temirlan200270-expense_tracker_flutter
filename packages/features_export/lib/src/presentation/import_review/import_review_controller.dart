import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// Состояние «зала ожидания» импорта до записи в БД.
class ImportReviewController extends StateNotifier<List<PendingImportExpense>> {
  ImportReviewController() : super(const []);

  /// Загрузить черновики и отсортировать по приоритету (дорогие + неуверенные сверху).
  void stage(List<PendingImportExpense> items) {
    final list = [...items];
    sortPendingImportsByReviewPriority(list);
    state = list;
  }

  void clear() => state = const [];

  /// Пересортировать текущий список.
  void sortByPriority() {
    final list = [...state];
    sortPendingImportsByReviewPriority(list);
    state = list;
  }

  void toggleInclusion(int index) {
    if (index < 0 || index >= state.length) return;
    final next = [...state];
    final e = next[index];
    next[index] = e.copyWith(isIncluded: !e.isIncluded);
    state = next;
  }

  /// Исключить строку из импорта (снять галочку).
  void skipAt(int index) {
    if (index < 0 || index >= state.length) return;
    final next = [...state];
    next[index] = next[index].copyWith(isIncluded: false);
    state = next;
  }

  /// Убрать строку из черновика (свайп «в мусор»).
  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    final next = [...state]..removeAt(index);
    state = next;
  }

  /// Ручная категория; при выборе — строка включается в импорт.
  void updateCategory(int index, String? categoryId) {
    if (index < 0 || index >= state.length) return;
    final next = [...state];
    final current = next[index];
    next[index] = current.copyWith(
      specifyEffectiveCategoryId: true,
      effectiveCategoryId: categoryId,
      isIncluded: categoryId != null ? true : current.isIncluded,
    );
    state = next;
  }

  /// Включить все строки с уверенностью не ниже [threshold] и с категорией.
  void confirmAllAboveThreshold(double threshold) {
    final next = <PendingImportExpense>[
      for (final e in state)
        if (e.confidence >= threshold &&
            e.predictedCategoryId != null &&
            e.effectiveCategoryId != null)
          e.copyWith(isIncluded: true)
        else
          e,
    ];
    state = next;
  }

  void confirmAllConfident() => confirmAllAboveThreshold(0.9);

  /// Вернуть чекбоксы к дефолту matching engine.
  void applyDefaultInclusion() {
    state = [
      for (final e in state)
        e.copyWith(isIncluded: e.defaultIsIncludedForReview),
    ];
  }

  int countWithSameSanitizedTitle(int index) {
    if (index < 0 || index >= state.length) return 0;
    final key = sanitizeTitleForMatch(state[index].parsed.note ?? '');
    if (key.isEmpty) return 1;
    return state
        .where((e) => sanitizeTitleForMatch(e.parsed.note ?? '') == key)
        .length;
  }

  /// Одна категория для всех строк с тем же санитизированным названием.
  void applyCategoryToSameSanitizedTitle(int index, String categoryId) {
    if (index < 0 || index >= state.length) return;
    final key = sanitizeTitleForMatch(state[index].parsed.note ?? '');
    if (key.isEmpty) return;
    final next = <PendingImportExpense>[];
    for (final e in state) {
      if (sanitizeTitleForMatch(e.parsed.note ?? '') == key) {
        next.add(
          e.copyWith(
            specifyEffectiveCategoryId: true,
            effectiveCategoryId: categoryId,
            isIncluded: true,
          ),
        );
      } else {
        next.add(e);
      }
    }
    state = next;
  }
}

final importReviewControllerProvider = StateNotifierProvider.autoDispose<
    ImportReviewController, List<PendingImportExpense>>(
  (ref) => ImportReviewController(),
);
