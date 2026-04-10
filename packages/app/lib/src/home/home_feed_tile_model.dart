import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

/// Presentation model для карточки ленты: domain mapping выполнен **один раз**
/// в провайдере, а не внутри каждого виджета карточки.
///
/// Виджет получает готовые данные для рендера — без `ref.watch(categories)`.
@immutable
class ExpenseTileModel {
  const ExpenseTileModel({
    required this.expense,
    required this.title,
    required this.isIncome,
    this.categoryName,
    this.categoryColorValue,
    this.categoryId,
    this.isCategoryExpense = true,
  });

  /// Исходная доменная сущность (нужна для delete / duplicate / edit).
  final Expense expense;

  /// Готовый заголовок (note или fallback «Расход» / «Доход»).
  final String title;

  final bool isIncome;

  /// Имя категории (null = без категории).
  final String? categoryName;

  /// Сырой цвет категории (int ARGB). Null = fallback по типу операции.
  final int? categoryColorValue;

  /// Id категории (для `CategoryVisuals.iconForCategory`).
  final String? categoryId;

  /// `true` если категория расходная (влияет на выбор иконки).
  final bool isCategoryExpense;

  /// Иконка карточки: из категории или fallback.
  IconData resolveIcon() {
    if (categoryId != null) {
      return CategoryVisuals.iconForCategory(
        categoryId: categoryId!,
        isExpenseCategory: isCategoryExpense,
        name: categoryName ?? '',
      );
    }
    return isIncome ? Icons.payments_outlined : Icons.receipt_long_outlined;
  }

  /// Фоновый цвет иконки с учётом темы.
  Color resolveIconBackground(ColorScheme cs) {
    if (categoryColorValue != null) {
      return CategoryColorHarmony.iconBackgroundTint(
        Color(categoryColorValue!),
        cs,
      );
    }
    final fallback = isIncome ? cs.tertiary : cs.error;
    return fallback.withValues(alpha: 0.12);
  }

  /// Цвет иконки переднего плана с учётом темы.
  Color resolveIconForeground(ColorScheme cs) {
    if (categoryColorValue != null) {
      return CategoryColorHarmony.foreground(Color(categoryColorValue!), cs);
    }
    return isIncome ? cs.tertiary : cs.error;
  }
}

/// Маппинг `Expense` + `List<Category>` → [ExpenseTileModel].
///
/// Вызывается один раз в провайдере, а не в каждом `build()`.
ExpenseTileModel mapExpenseToTile({
  required Expense expense,
  required List<Category> categories,
  required String Function(bool isIncome) fallbackTitle,
}) {
  Category? matched;
  final catId = expense.categoryId;
  if (catId != null) {
    for (final c in categories) {
      if (c.id == catId) {
        matched = c;
        break;
      }
    }
  }

  final title = (expense.note != null && expense.note!.trim().isNotEmpty)
      ? expense.note!.trim()
      : fallbackTitle(expense.type.isIncome);

  return ExpenseTileModel(
    expense: expense,
    title: title,
    isIncome: expense.type.isIncome,
    categoryName: matched?.name,
    categoryColorValue: matched?.colorValue,
    categoryId: matched?.id,
    isCategoryExpense: matched?.kind.isExpense ?? true,
  );
}
