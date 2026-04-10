import 'package:features_analytics/features_analytics.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import 'home_decision.dart';
import 'home_event.dart';
import 'home_ftue_state.dart';
import 'home_hero_insight_notifier.dart';
import 'home_screen_phase.dart';
import 'home_transition_log.dart';
import 'home_walkthrough_providers.dart';

// ---------------------------------------------------------------------------
// Consistency Rules (cross-system invariants)
// ---------------------------------------------------------------------------

/// Набор именованных правил. Каждое — pure function: входы → (флаг, причина).
///
/// Зачем отдельно: тестируемость, читаемость, масштабирование.
@visibleForTesting
abstract final class HomeConsistencyRules {
  /// Rule 1: FTUE не может продвигаться при error-фазе.
  static const ruleHeroErrorBlocksFtue = 'hero_error_blocks_ftue';

  static ({bool blocked, String? reason}) ftueBlockedByHeroError(
    UiScreenPhase phase,
  ) {
    if (phase == UiScreenPhase.error) {
      return (blocked: true, reason: 'Screen phase is error — FTUE frozen');
    }
    return (blocked: false, reason: null);
  }

  /// Rule 2: Инсайт подавлен в empty/loading/error — hero показывает FTUE-контент.
  static const ruleInsightSuppressedInEmptyState = 'insight_suppressed_empty';

  static bool insightSuppressed(UiScreenPhase phase) {
    return phase == UiScreenPhase.empty ||
        phase == UiScreenPhase.loading ||
        phase == UiScreenPhase.error;
  }

  /// Rule 3: Лента подавлена, если нет данных.
  static const ruleFeedSuppressed = 'feed_suppressed';

  static bool feedSuppressed(UiScreenPhase phase) {
    return phase == UiScreenPhase.loading ||
        phase == UiScreenPhase.error ||
        phase == UiScreenPhase.empty;
  }

  /// Rule 4: Walkthrough overlay подавлен при error / empty.
  static const ruleWalkthroughSuppressed = 'walkthrough_suppressed';

  static bool walkthroughSuppressed(UiScreenPhase phase) {
    return phase == UiScreenPhase.error || phase == UiScreenPhase.empty;
  }

  /// Rule 5: FTUE auto-advance welcome → firstExpense.
  static const ruleFtueAutoFirstExpense = 'ftue_auto_first_expense';

  static bool shouldAdvanceToFirstExpense(
    FtueStep currentStep,
    List<Expense>? expenses,
  ) {
    return currentStep == FtueStep.welcome &&
        expenses != null &&
        expenses.isNotEmpty;
  }

  /// Rule 6: FTUE auto-advance firstExpense → insightSeen.
  static const ruleFtueAutoInsightSeen = 'ftue_auto_insight_seen';

  static bool shouldAdvanceToInsightSeen(
    FtueStep currentStep,
    bool insightRevealed,
    String? stableLine,
  ) {
    return currentStep == FtueStep.firstExpense &&
        insightRevealed &&
        stableLine != null;
  }
}

// ---------------------------------------------------------------------------
// Decision Engine
// ---------------------------------------------------------------------------

/// Единственный Notifier, который собирает ВСЕ входы и выдаёт один [HomeDecision].
///
/// `HomePage.build()` подписывается **только на `homeDecisionProvider`**.
/// Все кросс-системные правила — здесь. Виджеты не принимают решения.
class HomeDecisionEngine extends AutoDisposeNotifier<HomeDecision> {
  final HomeTransitionLog _log = HomeTransitionLog();

  HomeTransitionLog get transitionLog => _log;

  @override
  HomeDecision build() {
    // -------------------------------------------------------------------------
    // Watch ALL inputs
    // -------------------------------------------------------------------------
    final expensesAsync = ref.watch(expensesStreamProvider);
    final financialAsync = ref.watch(financialSnapshotProvider);
    final ftue = ref.watch(homeFtueProvider);
    final walkthroughPending = ref.watch(homeWalkthroughPendingProvider);

    // -------------------------------------------------------------------------
    // 1. Resolve screen phase (data availability)
    // -------------------------------------------------------------------------
    final phase = resolveHomeScreenPhase(
      expenses: expensesAsync,
      financial: financialAsync,
    );

    // -------------------------------------------------------------------------
    // 2. Apply consistency rules → flags
    // -------------------------------------------------------------------------
    final ftueGuard = HomeConsistencyRules.ftueBlockedByHeroError(phase);
    final flags = HomeConsistencyFlags(
      ftueBlocked: ftueGuard.blocked,
      ftueBlockReason: ftueGuard.reason,
      feedSuppressed: HomeConsistencyRules.feedSuppressed(phase),
      insightSuppressed: HomeConsistencyRules.insightSuppressed(phase),
      walkthroughSuppressed:
          HomeConsistencyRules.walkthroughSuppressed(phase),
    );

    // -------------------------------------------------------------------------
    // 3. FTUE auto-advance (respects consistency guards)
    // -------------------------------------------------------------------------
    if (ftue.isFtueActive && !flags.ftueBlocked) {
      _autoAdvanceFtue(ftue, expensesAsync, ref);
    }

    // -------------------------------------------------------------------------
    // 4. Walkthrough effective value (raw flag ∧ ¬suppressed)
    // -------------------------------------------------------------------------
    final showWalkthrough = walkthroughPending && !flags.walkthroughSuppressed;

    // -------------------------------------------------------------------------
    // 5. Build decision
    // -------------------------------------------------------------------------
    final decision = HomeDecision(
      phase: phase,
      ftue: ftue,
      showWalkthrough: showWalkthrough,
      flags: flags,
      debugTransitionCount: _log.length,
    );

    // -------------------------------------------------------------------------
    // 6. Observability: record transition if state changed
    // -------------------------------------------------------------------------
    _recordTransitionIfChanged(decision, phase, flags);

    return decision;
  }

  void _autoAdvanceFtue(
    HomeFtueState ftue,
    AsyncValue<List<Expense>> expensesAsync,
    Ref ref,
  ) {
    final expenses = expensesAsync.valueOrNull;

    if (HomeConsistencyRules.shouldAdvanceToFirstExpense(
      ftue.step,
      expenses,
    )) {
      Future.microtask(() {
        ref.read(homeFtueProvider.notifier).markFirstExpense();
      });
      _log.record(StateTransitionRecord(
        timestamp: DateTime.now(),
        trigger: HomeEventKind.expensesChanged,
        from: 'ftue:${FtueStep.welcome.name}',
        to: 'ftue:${FtueStep.firstExpense.name}',
        rule: HomeConsistencyRules.ruleFtueAutoFirstExpense,
        detail: '${expenses?.length ?? 0} expenses appeared',
      ));
      return;
    }

    if (ftue.step == FtueStep.firstExpense) {
      final insight = ref.read(homeHeroInsightNotifierProvider);
      if (HomeConsistencyRules.shouldAdvanceToInsightSeen(
        ftue.step,
        insight.insightRevealed,
        insight.stableLine,
      )) {
        Future.microtask(() {
          ref.read(homeFtueProvider.notifier).advanceTo(FtueStep.insightSeen);
        });
        _log.record(StateTransitionRecord(
          timestamp: DateTime.now(),
          trigger: HomeEventKind.insightRevealed,
          from: 'ftue:${FtueStep.firstExpense.name}',
          to: 'ftue:${FtueStep.insightSeen.name}',
          rule: HomeConsistencyRules.ruleFtueAutoInsightSeen,
          detail: 'insight: "${insight.stableLine?.substring(0, 40)}…"',
        ));
      }
    }
  }

  void _recordTransitionIfChanged(
    HomeDecision next,
    UiScreenPhase phase,
    HomeConsistencyFlags flags,
  ) {
    final prev = _log.last;
    final prevPhaseStr = prev?.to.split(':').firstOrNull;
    final nextPhaseStr = 'phase:${phase.name}';

    if (prevPhaseStr != nextPhaseStr || prev == null) {
      _log.record(StateTransitionRecord(
        timestamp: DateTime.now(),
        trigger: HomeEventKind.expensesChanged,
        from: prev?.to ?? 'init',
        to: nextPhaseStr,
        rule: flags.ftueBlocked
            ? HomeConsistencyRules.ruleHeroErrorBlocksFtue
            : null,
        detail: _flagsSummary(flags),
      ));
    }
  }

  static String _flagsSummary(HomeConsistencyFlags f) {
    final parts = <String>[];
    if (f.ftueBlocked) parts.add('ftue_blocked');
    if (f.feedSuppressed) parts.add('feed_off');
    if (f.insightSuppressed) parts.add('insight_off');
    if (f.walkthroughSuppressed) parts.add('walkthrough_off');
    return parts.isEmpty ? 'all_clear' : parts.join(', ');
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final homeDecisionProvider =
    NotifierProvider.autoDispose<HomeDecisionEngine, HomeDecision>(
  HomeDecisionEngine.new,
);

/// Доступ к transition log для отладки (dev overlay, logger).
final homeTransitionLogProvider = Provider.autoDispose<HomeTransitionLog>((ref) {
  final engine = ref.watch(homeDecisionProvider.notifier);
  return engine.transitionLog;
});
