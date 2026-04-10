import 'package:easy_localization/easy_localization.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_feed_tile_model.dart';

/// Последние 5 операций, уже замапленные в [ExpenseTileModel].
///
/// Одна подписка на `expensesStreamProvider` + `categoriesStreamProvider`
/// вместо N подписок внутри каждой карточки.
final homeFeedTilesProvider = Provider.autoDispose<List<ExpenseTileModel>>((ref) {
  final expenses = ref.watch(expensesStreamProvider).valueOrNull;
  final categories = ref.watch(categoriesStreamProvider).valueOrNull;

  if (expenses == null) return const [];

  final cats = categories ?? const [];
  return expenses.take(5).map((e) {
    return mapExpenseToTile(
      expense: e,
      categories: cats,
      fallbackTitle: (isIncome) =>
          isIncome ? tr('home.feed.income') : tr('home.feed.expense'),
    );
  }).toList();
});
