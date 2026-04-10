import 'package:easy_localization/easy_localization.dart';
import 'package:features_analytics/features_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import 'home_decision_hero_helper.dart';

/// Схлопывает нарратив Decision Engine в [UxDecisionView] (SSS UX Polish v1).
class UxDecisionMapper {
  UxDecisionMapper._();

  /// Snapshot → один доминирующий инсайт (лестница SSS: лимит > поведение > предупреждение).
  static UxDecisionView mapSnapshot(
    HomeDecisionSnapshot snapshot, {
    required ColorScheme colorScheme,
    required NumberFormat formatter,
  }) {
    final budget = snapshot.budgetPressure;
    final tier = snapshot.stateTier;

    // 1. Critical limit — бюджет пробит
    if (budget != null && budget.worstLineStatus == BudgetStatus.exceeded) {
      return UxDecisionView(
        coreMessage: tr('home.insight.budget_exceeded.title'),
        contextLine: tr('home.insight.budget_exceeded.context'),
        actionHint: tr('home.insight.budget_exceeded.hint'),
        tone: UxFinancialTone.risk,
      );
    }

    // 2. Critical behavior — опасный темп (tier danger)
    if (tier == HomeFinancialStateTier.danger) {
      final narrative = HomeDecisionHeroHelper.build(
        colorScheme: colorScheme,
        snapshot: snapshot,
        formatter: formatter,
      );
      final ux = fromHomeNarrative(narrative: narrative, tier: tier);
      final runwayHint = _hintForRunway(snapshot.runwayDays);
      return UxDecisionView(
        coreMessage: ux.coreMessage,
        contextLine: ux.contextLine,
        actionHint: runwayHint ?? ux.actionHint,
        tone: UxFinancialTone.risk,
      );
    }

    // 3. Warning limit — лимит на исходе (порог предупреждения или ≥90% утилизации)
    if (budget != null && _isBudgetWarningRung(budget)) {
      return UxDecisionView(
        coreMessage: tr('home.insight.budget_warning.title'),
        contextLine: tr('home.insight.budget_warning.context'),
        actionHint: tr('home.insight.budget_warning.hint'),
        tone: UxFinancialTone.watch,
      );
    }

    // 4. Warning behavior — локальная аномалия
    if (tier == HomeFinancialStateTier.caution) {
      final narrative = HomeDecisionHeroHelper.build(
        colorScheme: colorScheme,
        snapshot: snapshot,
        formatter: formatter,
      );
      return fromHomeNarrative(narrative: narrative, tier: tier);
    }

    // 5. Safe — без детального поведенческого слоя
    final narrative = HomeDecisionHeroHelper.build(
      colorScheme: colorScheme,
      snapshot: snapshot,
      formatter: formatter,
    );
    final detail = narrative.detailLine?.trim();
    if (detail == null || detail.isEmpty) {
      return UxDecisionView(
        coreMessage: tr('home.insight.safe.title'),
        contextLine: tr('home.insight.safe.context'),
        actionHint: tr('home.insight.safe.hint'),
        tone: UxFinancialTone.safe,
      );
    }
    return fromHomeNarrative(narrative: narrative, tier: tier);
  }

  static bool _isBudgetWarningRung(HomeBudgetPressure b) {
    return b.worstLineStatus != BudgetStatus.exceeded &&
        (b.worstLineStatus == BudgetStatus.warning ||
            b.aggregateUtilization >= 0.9);
  }

  /// Подсказка по прогнозу «запаса дней» при опасном темпе.
  static String? _hintForRunway(int? runwayDays) {
    if (runwayDays == null) return null;
    if (runwayDays <= 3) {
      return tr(
        'home.insight.runway.critical',
        args: [runwayDays.toString()],
      );
    }
    return tr(
      'home.insight.runway.warning',
      args: [runwayDays.toString()],
    );
  }

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
