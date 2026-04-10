import 'package:features_analytics/features_analytics.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/budget_hero_rate_limit_store.dart';
import 'insight_feedback_providers.dart';
import '../settings/settings_providers.dart';

/// Доступ к счётчику показов бюджетного hero.
final budgetHeroRateLimitStoreProvider = Provider<BudgetHeroRateLimitStore>(
  (ref) => BudgetHeroRateLimitStore(ref.watch(sharedPreferencesProvider)),
);

/// Бюджеты, у которых исчерпан лимит показов за скользящее окно.
final budgetHeroRateLimitedIdsProvider = Provider.autoDispose<Set<String>>(
  (ref) {
    final store = ref.watch(budgetHeroRateLimitStoreProvider);
    final async = ref.watch(budgetsWithSpendingProvider);
    final list = async.valueOrNull ?? [];
    return list
        .where((bw) => store.isRateLimited(bw.budget.id))
        .map((bw) => bw.budget.id)
        .toSet();
  },
);

/// Бюджеты с сильным негативным feedback по hero — мягко снижаем приоритет выбора.
final budgetHeroSoftDeprioritizeIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final budgets = await ref.watch(budgetsWithSpendingProvider.future);
  if (budgets.isEmpty) return {};
  final repo = ref.read(insightFeedbackRepositoryProvider);
  final out = <String>{};
  for (final bw in budgets) {
    final seg = insightFingerprintIdSegment(bw.budget.id);
    final prefix = 'v2_b_${seg}_';
    final stats =
        await repo.statsForInsightFingerprintPrefix(prefix, withinDays: 14);
    if (stats.total >= 4 && stats.notUsefulRatio >= 0.6) {
      out.add(bw.budget.id);
    }
  }
  return out;
});
