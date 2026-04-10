// Стабилизация инсайта hero: таймеры, feedback, rate-limit — отдельно от виджета.
import 'dart:async';

import 'package:features_analytics/features_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import 'home_insight_identity.dart';
import 'home_hero_resolved_insight.dart';
import 'home_ux_insight_logic.dart';
import 'home_wallet_shell.dart';
import '../providers/insight_feedback_providers.dart';
import '../providers/insight_reveal_sync_provider.dart';
import '../providers/budget_hero_depriority_provider.dart';

/// Состояние стабилизации инсайта hero + последняя пара ux/raw для UI.
class HomeHeroInsightState {
  const HomeHeroInsightState({
    this.resolved,
    this.insightRevealed = false,
    this.stableLine,
    this.stableContext,
    this.stableHint,
    this.feedbackSent = false,
    this.showSituationImproved = false,
    this.heroEnterAnimationPlayed = false,
  });

  final HomeHeroResolvedPair? resolved;
  final bool insightRevealed;
  final String? stableLine;
  final String? stableContext;
  final String? stableHint;
  final bool feedbackSent;
  final bool showSituationImproved;
  final bool heroEnterAnimationPlayed;

  HomeHeroInsightState copyWith({
    HomeHeroResolvedPair? resolved,
    bool? insightRevealed,
    String? stableLine,
    String? stableContext,
    String? stableHint,
    bool? feedbackSent,
    bool? showSituationImproved,
    bool? heroEnterAnimationPlayed,
  }) {
    return HomeHeroInsightState(
      resolved: resolved ?? this.resolved,
      insightRevealed: insightRevealed ?? this.insightRevealed,
      stableLine: stableLine ?? this.stableLine,
      stableContext: stableContext ?? this.stableContext,
      stableHint: stableHint ?? this.stableHint,
      feedbackSent: feedbackSent ?? this.feedbackSent,
      showSituationImproved: showSituationImproved ?? this.showSituationImproved,
      heroEnterAnimationPlayed:
          heroEnterAnimationPlayed ?? this.heroEnterAnimationPlayed,
    );
  }
}

/// Таймеры, стабилизация текста, feedback и rate-limit — вне виджета hero.
///
/// Дальнейший рост: вынести чистый расчёт в `InsightEngine`, персистенс в
/// `InsightPersistence`, таймеры раскрытия — в узкий `InsightRevealController`;
/// явная фаза UI — `enum` вместо набора bool (см. обсуждение state machine).
final homeHeroInsightNotifierProvider =
    NotifierProvider.autoDispose<HomeHeroInsightNotifier, HomeHeroInsightState>(
  HomeHeroInsightNotifier.new,
);

class HomeHeroInsightNotifier extends AutoDisposeNotifier<HomeHeroInsightState> {
  static const Duration _kMinInsightDisplay = Duration(seconds: 3);
  static const Duration _kInsightRevealDelay = Duration(milliseconds: 220);

  Timer? _revealTimer;
  Timer? _persistResyncTimer;
  Timer? _improvedBannerTimer;

  ColorScheme? _colorScheme;
  NumberFormat? _formatter;

  int _lastSyncHash = -1;
  DateTime? _insightVisibleSince;
  HomeFinancialStateTier? _lastVisibleTier;

  bool get _hasFormattingContext =>
      _colorScheme != null && _formatter != null;

  @override
  HomeHeroInsightState build() {
    ref.onDispose(() {
      _revealTimer?.cancel();
      _persistResyncTimer?.cancel();
      _improvedBannerTimer?.cancel();
    });

    ref.listen<HomeHeroComputationInputs?>(
      homeHeroComputationInputsProvider,
      (prev, next) {
        if (next != null && _hasFormattingContext) {
          if (prev != null) {
            _onTierTransition(prev.snapshot.stateTier, next.snapshot.stateTier);
          }
          _syncInsightDisplay();
        }
      },
    );

    ref.listen(insightRevealSyncProvider, (_, __) {
      if (_hasFormattingContext) {
        final inputs = ref.read(homeHeroComputationInputsProvider);
        if (inputs != null) {
          _syncInsightDisplay();
        }
      }
    });

    return const HomeHeroInsightState();
  }

  /// Тема и формат валюты из виджета (mapper зависит от [ColorScheme] и локали).
  /// Не вызываем лишний [_syncInsightDisplay] на каждом rebuild: [ColorScheme] каждый кадр новый по ссылке.
  void setFormattingContext({
    required ColorScheme colorScheme,
    required NumberFormat formatter,
  }) {
    final schemeVisualChange = _colorScheme == null ||
        _colorScheme!.brightness != colorScheme.brightness ||
        _colorScheme!.primary != colorScheme.primary;
    final formatChanged = _formatter?.locale != formatter.locale ||
        _formatter?.currencySymbol != formatter.currencySymbol;
    _colorScheme = colorScheme;
    _formatter = formatter;
    if (schemeVisualChange || formatChanged) {
      final inputs = ref.read(homeHeroComputationInputsProvider);
      if (inputs != null) {
        _syncInsightDisplay();
      }
    }
  }

  void markHeroEnterAnimationPlayed() {
    if (state.heroEnterAnimationPlayed) return;
    state = state.copyWith(heroEnterAnimationPlayed: true);
  }

  Future<void> sendFeedback(FeedbackType type) async {
    if (state.feedbackSent) return;
    final inputs = ref.read(homeHeroComputationInputsProvider);
    if (inputs == null || !_hasFormattingContext) return;

    final pair = computeHomeHeroResolved(
      inputs: inputs,
      colorScheme: _colorScheme!,
      formatter: _formatter!,
    );
    final classKey = homeInsightClassKeyForHero(
      snapshot: inputs.snapshot,
      raw: pair.raw,
    );
    try {
      await ref.read(insightFeedbackRepositoryProvider).record(
            InsightFeedback(
              id:
                  '${DateTime.now().microsecondsSinceEpoch}_${classKey.hashCode.abs()}',
              fingerprint: classKey,
              useful: type == FeedbackType.helpful,
              timestamp: DateTime.now(),
            ),
          );
      ref.invalidate(financialSnapshotProvider);
      ref.invalidate(budgetHeroSoftDeprioritizeIdsProvider);
      state = state.copyWith(feedbackSent: true);
      HapticUtils.selection();
    } catch (_) {}
  }

  void _onTierTransition(
    HomeFinancialStateTier oldTier,
    HomeFinancialStateTier newTier,
  ) {
    if (oldTier == HomeFinancialStateTier.danger &&
        (newTier == HomeFinancialStateTier.caution ||
            newTier == HomeFinancialStateTier.stable)) {
      _improvedBannerTimer?.cancel();
      state = state.copyWith(showSituationImproved: true);
      _improvedBannerTimer = Timer(const Duration(seconds: 6), () {
        state = state.copyWith(showSituationImproved: false);
      });
    }
    if (newTier == HomeFinancialStateTier.danger) {
      _improvedBannerTimer?.cancel();
      state = state.copyWith(showSituationImproved: false);
    }
  }

  void _schedulePersistResync() {
    _persistResyncTimer?.cancel();
    final since = _insightVisibleSince;
    if (since == null) return;
    var remaining = _kMinInsightDisplay - DateTime.now().difference(since);
    if (remaining.isNegative) remaining = Duration.zero;
    _persistResyncTimer = Timer(remaining, () {
      final inputs = ref.read(homeHeroComputationInputsProvider);
      if (inputs != null && _hasFormattingContext) {
        _syncInsightDisplay();
      }
    });
  }

  void _publishRevealState(String fp, HomeHeroInsightResult raw) {
    final line = raw.insightLine?.trim();
    if (line == null || line.isEmpty) return;
    ref.read(insightRevealSyncProvider.notifier).state =
        InsightRevealSyncState(fingerprint: fp, revealed: true);
  }

  int _contentHash(HomeHeroComputationInputs inputs) {
    final depSorted = inputs.softDeprioritizeBudgetIds.toList()..sort();
    final rateSorted = inputs.rateLimitedBudgetIds.toList()..sort();
    final s = inputs.snapshot;
    final stats = s.monthStats;
    return Object.hash(
      s.stateTier,
      stats.balance,
      stats.totalExpenses,
      s.behaviorInsight?.variant,
      s.spendingTrend,
      inputs.budgetsAsync.valueOrNull?.length,
      Object.hashAll(depSorted),
      Object.hashAll(rateSorted),
    );
  }

  Future<void> _persistBudgetHeroShow(String budgetId) async {
    final recorded = await ref
        .read(budgetHeroRateLimitStoreProvider)
        .recordShowIfGapped(budgetId);
    if (recorded) {
      ref.invalidate(budgetHeroRateLimitedIdsProvider);
    }
  }

  void _syncInsightDisplay() {
    final inputs = ref.read(homeHeroComputationInputsProvider);
    if (inputs == null || !_hasFormattingContext) return;

    final snapshot = inputs.snapshot;
    final pair = computeHomeHeroResolved(
      inputs: inputs,
      colorScheme: _colorScheme!,
      formatter: _formatter!,
    );
    final raw = pair.raw;

    final h = _contentHash(inputs);
    if (h != _lastSyncHash) {
      _lastSyncHash = h;
    }

    final revealFp = homeHeroRevealFingerprintForSync(
      snapshot: snapshot,
      raw: raw,
    );

    final fromBudget = raw.budgetProgress != null;
    var immediateReveal = false;
    var startTimer = false;
    var bumpInsightVisibleSince = false;

    String? stableLine = state.stableLine;
    String? stableContext = state.stableContext;
    String? stableHint = state.stableHint;
    var feedbackSent = state.feedbackSent;

    if (fromBudget) {
      stableLine = raw.insightLine;
      stableContext = raw.insightContextLine;
      stableHint = raw.actionHint;
      immediateReveal = true;
      feedbackSent = false;
      bumpInsightVisibleSince = true;
      final bid = raw.budgetEntityId;
      final line = raw.insightLine;
      if (bid != null && line != null && line.trim().isNotEmpty) {
        unawaited(_persistBudgetHeroShow(bid));
      }
    } else if (raw.insightLine == null || raw.insightLine!.trim().isEmpty) {
      stableLine = raw.insightLine;
      stableContext = raw.insightContextLine;
      stableHint = raw.actionHint;
      immediateReveal = true;
      bumpInsightVisibleSince = true;
    } else if (stableLine != null &&
        uxCoreRoughlySame(stableLine, raw.insightLine!)) {
      stableHint = raw.actionHint ?? stableHint;
      _revealTimer?.cancel();
      immediateReveal = true;
    } else {
      final candidate = raw.insightLine!;
      final severityUp = homeFinancialSeverityIncreased(
        _lastVisibleTier,
        snapshot.stateTier,
      );
      if (state.insightRevealed &&
          stableLine != null &&
          !uxCoreRoughlySame(stableLine, candidate) &&
          _insightVisibleSince != null &&
          DateTime.now().difference(_insightVisibleSince!) <
              _kMinInsightDisplay &&
          !severityUp) {
        _schedulePersistResync();
        return;
      }

      stableLine = raw.insightLine;
      stableContext = raw.insightContextLine;
      stableHint = raw.actionHint;
      feedbackSent = false;

      if (state.insightRevealed) {
        immediateReveal = true;
        startTimer = false;
        _revealTimer?.cancel();
        bumpInsightVisibleSince = true;
      } else {
        final sync = ref.read(insightRevealSyncProvider);
        if (sync.revealed && sync.fingerprint == revealFp) {
          immediateReveal = true;
          startTimer = false;
          _revealTimer?.cancel();
          bumpInsightVisibleSince = true;
        } else {
          startTimer = true;
          immediateReveal = false;
        }
      }
    }

    _revealTimer?.cancel();

    var insightRevealed = state.insightRevealed;
    if (immediateReveal) {
      insightRevealed = true;
    } else if (startTimer) {
      insightRevealed = false;
      final fpCaptured = revealFp;
      _revealTimer = Timer(_kInsightRevealDelay, () {
        state = state.copyWith(
          insightRevealed: true,
          resolved: pair,
        );
        _insightVisibleSince = DateTime.now();
        _lastVisibleTier = snapshot.stateTier;
        _publishRevealState(fpCaptured, raw);
      });
    }

    state = state.copyWith(
      resolved: pair,
      insightRevealed: insightRevealed,
      stableLine: stableLine,
      stableContext: stableContext,
      stableHint: stableHint,
      feedbackSent: feedbackSent,
    );

    if (bumpInsightVisibleSince) {
      _insightVisibleSince = DateTime.now();
      _lastVisibleTier = snapshot.stateTier;
      _publishRevealState(revealFp, raw);
    }
  }
}
