import 'package:features_analytics/features_analytics.dart';

import 'home_wallet_shell.dart';

/// Класс инсайта для БД feedback и агрегации (v2).
String homeInsightClassKeyForHero({
  required HomeDecisionSnapshot snapshot,
  required HomeHeroInsightResult raw,
}) {
  final fromBudget = raw.budgetProgress != null;
  if (fromBudget) {
    return homeInsightClassKeyV2(
      fromBudget: true,
      behaviorVariant: null,
      categoryOrBudgetScopeId: raw.budgetEntityId,
      tier: snapshot.stateTier,
    );
  }
  final ins = snapshot.behaviorInsight;
  return homeInsightClassKeyV2(
    fromBudget: false,
    behaviorVariant: ins?.variant,
    categoryOrBudgetScopeId: ins?.variant == HomeInsightVariant.categoryFocus
        ? ins?.topContributor?.categoryId
        : '_',
    tier: snapshot.stateTier,
  );
}

/// Ключ синхронизации раскрытия (класс + час UTC).
String homeHeroRevealFingerprintForSync({
  required HomeDecisionSnapshot snapshot,
  required HomeHeroInsightResult raw,
}) {
  final ck = homeInsightClassKeyForHero(snapshot: snapshot, raw: raw);
  return homeInsightRevealSyncKey(classKey: ck);
}
