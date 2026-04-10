// Провайдер входов и функция «ux + raw» для hero без дублирования mapper/resolve.
import 'package:features_analytics/features_analytics.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

import 'ux_decision_mapper.dart';
import 'home_wallet_shell.dart';
import '../providers/budget_hero_depriority_provider.dart';

/// Результат однократного прогона [UxDecisionMapper] + [resolveHomeHeroInsight].
///
/// Единая точка, чтобы не вызывать mapper/resolve по нескольку раз за кадр.
class HomeHeroResolvedPair {
  const HomeHeroResolvedPair({
    required this.ux,
    required this.raw,
  });

  final UxDecisionView ux;
  final HomeHeroInsightResult raw;
}

/// Снимок входов для hero-инсайта (без [ColorScheme] / [NumberFormat] — они из темы виджета).
class HomeHeroComputationInputs {
  const HomeHeroComputationInputs({
    required this.snapshot,
    required this.budgetsAsync,
    required this.softDeprioritizeBudgetIds,
    required this.rateLimitedBudgetIds,
  });

  final HomeDecisionSnapshot snapshot;
  final AsyncValue<List<BudgetWithSpending>> budgetsAsync;
  final Set<String> softDeprioritizeBudgetIds;
  final Set<String> rateLimitedBudgetIds;
}

/// Текущие входные данные для расчёта инсайта (финансы + бюджеты + deprioritize/rate-limit).
final homeHeroComputationInputsProvider =
    Provider.autoDispose<HomeHeroComputationInputs?>((ref) {
  final fin = ref.watch(financialSnapshotProvider);
  final budgets = ref.watch(budgetsWithSpendingProvider);
  final soft =
      ref.watch(budgetHeroSoftDeprioritizeIdsProvider).valueOrNull ?? {};
  final rate = ref.watch(budgetHeroRateLimitedIdsProvider);

  return fin.maybeWhen(
    data: (data) => HomeHeroComputationInputs(
      snapshot: data.decision,
      budgetsAsync: budgets,
      softDeprioritizeBudgetIds: soft,
      rateLimitedBudgetIds: rate,
    ),
    orElse: () => null,
  );
});

/// Одна точка: [UxDecisionMapper.mapSnapshot] + [resolveHomeHeroInsight].
///
/// При росте стоимости расчёта: кэш по хэшу входов ([homeHeroComputationInputsProvider])
/// или мемоизация в провайдере с `select`.
HomeHeroResolvedPair computeHomeHeroResolved({
  required HomeHeroComputationInputs inputs,
  required ColorScheme colorScheme,
  required NumberFormat formatter,
}) {
  final ux = UxDecisionMapper.mapSnapshot(
    inputs.snapshot,
    colorScheme: colorScheme,
    formatter: formatter,
  );
  final raw = resolveHomeHeroInsight(
    budgetsAsync: inputs.budgetsAsync,
    ux: ux,
    formatter: formatter,
    softDeprioritizeBudgetIds: inputs.softDeprioritizeBudgetIds,
    rateLimitedBudgetIds: inputs.rateLimitedBudgetIds,
    unifiedHeroBudgetPressure: inputs.snapshot.budgetPressure,
  );
  return HomeHeroResolvedPair(ux: ux, raw: raw);
}
