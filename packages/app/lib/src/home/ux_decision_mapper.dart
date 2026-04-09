import 'package:features_analytics/features_analytics.dart';
import 'package:shared_models/shared_models.dart';

import 'home_decision_hero_helper.dart';

/// Схлопывает нарратив Decision Engine в [UxDecisionView] (SSS UX Polish v1).
class UxDecisionMapper {
  UxDecisionMapper._();

  static UxDecisionView fromHomeNarrative({
    required HomeDecisionHeroNarrative narrative,
    required HomeFinancialStateTier tier,
  }) {
    final detail = narrative.detailLine?.trim();
    final hasDetail = detail != null && detail.isNotEmpty;

    return UxDecisionView(
      coreMessage: hasDetail ? detail : narrative.stateTitle,
      contextLine: hasDetail ? narrative.stateTitle : null,
      actionHint: narrative.microAction,
      tone: switch (tier) {
        HomeFinancialStateTier.stable => UxFinancialTone.safe,
        HomeFinancialStateTier.caution => UxFinancialTone.watch,
        HomeFinancialStateTier.danger => UxFinancialTone.risk,
      },
    );
  }
}
