import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_analytics/features_analytics.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import 'home_layout_shell.dart';
import 'home_ux_insight_logic.dart';
import 'home_wallet_shell.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static Widget _headerActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedCircleIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: tr('analytics.title'),
          onPressed: () => context.push('/analytics'),
        ),
        Padding(
          padding: const EdgeInsets.only(left: HomeLayoutSpacing.s8),
          child: Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: PopupMenuButton<void>(
              tooltip: tr('settings'),
              icon: Icon(Icons.tune_rounded, color: cs.onSurface, size: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(tr('budget.title')),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/budgets');
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: Text(tr('debts.title')),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/debts');
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(tr('categories.title')),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/categories');
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.repeat),
                    title: Text(tr('recurring.title')),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/recurring');
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: Text(tr('export.title')),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/export');
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.download),
                    title: Text(tr('import.title')),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/import');
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(tr('settings')),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    final financialAsync = ref.watch(financialSnapshotProvider);
    final recentExpensesAsync = ref.watch(expensesStreamProvider);
    final budgetsAsync = ref.watch(budgetsWithSpendingProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(financialSnapshotProvider.future),
            ref.refresh(expensesStreamProvider.future),
            ref.refresh(budgetsWithSpendingProvider.future),
          ]);
        },
        child: recentExpensesAsync.when(
          data: (allExpenses) {
            final globalEmpty = allExpenses.isEmpty;
            final recentForHome = allExpenses.take(5).toList();

            return HomeLayoutShell(
              physics: const AlwaysScrollableScrollPhysics(),
              header: HomeWalletHeader(
                topActions: _headerActions(context),
              ),
              hero: globalEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        homeWalletHeroCard(
                          insightLine: tr('home.hero.ftue_micro'),
                          balanceAmountFormatted: formatter.format(0),
                          expensesFormatted: formatter.format(0),
                          incomeFormatted: formatter.format(0),
                          forecastFormatted: tr('home.hero.forecast_na'),
                          isCompactFtue: true,
                        )
                            .animate()
                            .fadeIn(
                              duration: AppMotion.standard,
                              curve: AppMotion.curve,
                            )
                            .slideY(
                              begin: 0.04,
                              end: 0,
                              duration: AppMotion.screen,
                              curve: AppMotion.curve,
                            ),
                        SizedBox(height: HomeLayoutSpacing.s16),
                        PrimaryActionButton(
                          onPressed: () => context.push('/expenses/new'),
                          child: Text(
                            tr('home.hero.new_operation'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        SizedBox(height: HomeLayoutSpacing.s8),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              HapticUtils.selection();
                              context.push('/import');
                            },
                            icon: const Icon(
                              Icons.upload_file,
                              size: 20,
                            ),
                            label: Text(tr('home.ftue.import_cta')),
                          ),
                        ),
                      ],
                    )
                  : financialAsync.when(
                      data: (fin) {
                        final forecastStr = fin.decision.forecast != null
                            ? formatter
                                .format(fin.decision.forecast!.projectedExpenses)
                            : tr('home.hero.forecast_na');
                        return _HomeLoadedHeroBlock(
                          formatter: formatter,
                          snapshot: fin.decision,
                          stats: fin.decision.monthStats,
                          budgetsAsync: budgetsAsync,
                          forecastStr: forecastStr,
                        );
                      },
                      loading: () => const _WalletHeroLoadingCard(),
                      error: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr('home.stats_error'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.error,
                                ),
                          ),
                          SizedBox(height: HomeLayoutSpacing.s16),
                          PrimaryActionButton(
                            onPressed: () => context.push('/expenses/new'),
                            child: Text(
                              tr('home.hero.new_operation'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
              feedHeader: globalEmpty
                  ? null
                  : SectionHeader(
                      variant: SectionHeaderVariant.mutedLabel,
                      title: tr('home.feed.recent_upper'),
                      trailing: TextButton(
                        onPressed: () => context.push('/expenses'),
                        child: Text(
                          tr('home.feed.all_link'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
              feedSlivers: globalEmpty
                  ? const <Widget>[]
                  : [
                      SliverPadding(
                        padding: HomeLayoutSpacing.feedOuter,
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final expense = recentForHome[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: HomeLayoutSpacing.s12,
                                ),
                                child: _HomeFeedCard(
                                  expense: expense,
                                  formatter: formatter,
                                  showDayHeader: _shouldShowDayHeader(
                                    recentForHome,
                                    index,
                                  ),
                                  dayHeaderText: _dayHeaderText(
                                    context,
                                    expense.occurredAt,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(
                                      duration: AppMotion.standard,
                                      delay: (AppMotion.staggerInterval *
                                          index),
                                      curve: AppMotion.curve,
                                    )
                                    .slideY(
                                      begin: 0.06,
                                      end: 0,
                                      duration: AppMotion.standard,
                                      delay: (AppMotion.staggerInterval *
                                          index),
                                      curve: AppMotion.curve,
                                    ),
                              );
                            },
                            childCount: recentForHome.length,
                          ),
                        ),
                      ),
                    ],
              bottomSpacerHeight:
                  globalEmpty ? HomeLayoutSpacing.s24 : null,
            );
          },
          loading: () => HomeLayoutShell(
            physics: const AlwaysScrollableScrollPhysics(),
            header: HomeWalletHeader(
              topActions: _headerActions(context),
            ),
            hero: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _WalletHeroLoadingCard(),
                SizedBox(height: HomeLayoutSpacing.s16),
                const SkeletonList(itemCount: 4),
              ],
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(HomeLayoutSpacing.s24),
              child: Text(
                tr('home.transactions_error'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _shouldShowDayHeader(List<Expense> list, int index) {
    if (index == 0) return true;
    final a = list[index - 1].occurredAt;
    final b = list[index].occurredAt;
    return !_isSameCalendarDay(a, b);
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dayHeaderText(BuildContext context, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    if (target == today) return tr('home.feed.today');
    if (target == today.subtract(const Duration(days: 1))) {
      return tr('home.feed.yesterday');
    }
    return DateFormat.yMMMd(context.locale.toLanguageTag()).format(d);
  }
}

/// Hero с градиентом по тону, стабильным текстом, задержкой показа инсайта и feedback.
class _HomeLoadedHeroBlock extends ConsumerStatefulWidget {
  const _HomeLoadedHeroBlock({
    required this.formatter,
    required this.snapshot,
    required this.stats,
    required this.budgetsAsync,
    required this.forecastStr,
  });

  final NumberFormat formatter;
  final HomeDecisionSnapshot snapshot;
  final AnalyticsStats stats;
  final AsyncValue<List<BudgetWithSpending>> budgetsAsync;
  final String forecastStr;

  @override
  ConsumerState<_HomeLoadedHeroBlock> createState() =>
      _HomeLoadedHeroBlockState();
}

class _HomeLoadedHeroBlockState extends ConsumerState<_HomeLoadedHeroBlock> {
  /// Минимум времени, пока показываем текущий инсайт, прежде чем сменить на другой.
  static const Duration _kMinInsightDisplay = Duration(seconds: 3);

  static const Duration _kInsightRevealDelay = Duration(milliseconds: 220);

  Timer? _revealTimer;
  Timer? _persistResyncTimer;
  Timer? _improvedBannerTimer;
  bool _showSituationImproved = false;
  bool _insightRevealed = false;
  String? _stableLine;
  String? _stableContext;
  String? _stableHint;
  bool _feedbackSent = false;
  int _lastSyncHash = -1;

  /// Когда пользователь увидел текущий (раскрытый) инсайт — для окна стабильности.
  DateTime? _insightVisibleSince;

  /// Tier на момент последнего закреплённого инсайта (для persistence + severity bypass).
  HomeFinancialStateTier? _lastVisibleTier;

  /// Feedback по бюджету → мягкий штраф при выборе строки hero (см. [pickBudgetForHeroInsight]).
  Set<String> _budgetSoftDepIds = {};

  /// Исчерпан лимит показов бюджета в hero за окно.
  Set<String> _budgetRateLimitedIds = {};

  @override
  void dispose() {
    _revealTimer?.cancel();
    _persistResyncTimer?.cancel();
    _improvedBannerTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HomeLoadedHeroBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ot = oldWidget.snapshot.stateTier;
    final nt = widget.snapshot.stateTier;
    if (ot == HomeFinancialStateTier.danger &&
        (nt == HomeFinancialStateTier.caution ||
            nt == HomeFinancialStateTier.stable)) {
      _improvedBannerTimer?.cancel();
      setState(() => _showSituationImproved = true);
      _improvedBannerTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => _showSituationImproved = false);
      });
    }
    if (nt == HomeFinancialStateTier.danger) {
      _improvedBannerTimer?.cancel();
      setState(() => _showSituationImproved = false);
    }
  }

  void _schedulePersistResync() {
    _persistResyncTimer?.cancel();
    final since = _insightVisibleSince;
    if (since == null) return;
    var remaining = _kMinInsightDisplay - DateTime.now().difference(since);
    if (remaining.isNegative) remaining = Duration.zero;
    _persistResyncTimer = Timer(remaining, () {
      if (mounted) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _syncInsightDisplay());
      }
    });
  }

  void _publishRevealState(String fp, HomeHeroInsightResult raw) {
    final line = raw.insightLine?.trim();
    if (line == null || line.isEmpty) return;
    ref.read(insightRevealSyncProvider.notifier).state =
        InsightRevealSyncState(fingerprint: fp, revealed: true);
  }

  int _contentHash() {
    final depSorted = _budgetSoftDepIds.toList()..sort();
    final rateSorted = _budgetRateLimitedIds.toList()..sort();
    return Object.hash(
      widget.snapshot.stateTier,
      widget.stats.balance,
      widget.stats.totalExpenses,
      widget.snapshot.behaviorInsight?.variant,
      widget.snapshot.spendingTrend,
      widget.budgetsAsync.valueOrNull?.length,
      Object.hashAll(depSorted),
      Object.hashAll(rateSorted),
    );
  }

  Future<void> _persistBudgetHeroShow(String budgetId) async {
    final recorded = await ref
        .read(budgetHeroRateLimitStoreProvider)
        .recordShowIfGapped(budgetId);
    if (recorded && mounted) {
      ref.invalidate(budgetHeroRateLimitedIdsProvider);
    }
  }

  void _syncInsightDisplay() {
    if (!mounted) return;
    final narrative = HomeDecisionHeroHelper.build(
      colorScheme: Theme.of(context).colorScheme,
      snapshot: widget.snapshot,
      formatter: widget.formatter,
    );
    final ux = UxDecisionMapper.fromHomeNarrative(
      narrative: narrative,
      tier: widget.snapshot.stateTier,
    );
    final raw = resolveHomeHeroInsight(
      budgetsAsync: widget.budgetsAsync,
      ux: ux,
      formatter: widget.formatter,
      softDeprioritizeBudgetIds: _budgetSoftDepIds,
      rateLimitedBudgetIds: _budgetRateLimitedIds,
    );
    final revealFp = homeHeroRevealFingerprintForSync(
      snapshot: widget.snapshot,
      raw: raw,
    );

    final fromBudget = raw.budgetProgress != null;
    var immediateReveal = false;
    var startTimer = false;
    var bumpInsightVisibleSince = false;

    if (fromBudget) {
      _stableLine = raw.insightLine;
      _stableContext = raw.insightContextLine;
      _stableHint = raw.actionHint;
      immediateReveal = true;
      _feedbackSent = false;
      bumpInsightVisibleSince = true;
      final bid = raw.budgetEntityId;
      final line = raw.insightLine;
      if (bid != null && line != null && line.trim().isNotEmpty) {
        unawaited(_persistBudgetHeroShow(bid));
      }
    } else if (raw.insightLine == null || raw.insightLine!.trim().isEmpty) {
      _stableLine = raw.insightLine;
      _stableContext = raw.insightContextLine;
      _stableHint = raw.actionHint;
      immediateReveal = true;
      bumpInsightVisibleSince = true;
    } else if (_stableLine != null &&
        uxCoreRoughlySame(_stableLine!, raw.insightLine!)) {
      _stableHint = raw.actionHint ?? _stableHint;
      _revealTimer?.cancel();
      immediateReveal = true;
    } else {
      final candidate = raw.insightLine!;
      final severityUp = homeFinancialSeverityIncreased(
        _lastVisibleTier,
        widget.snapshot.stateTier,
      );
      if (_insightRevealed &&
          _stableLine != null &&
          !uxCoreRoughlySame(_stableLine!, candidate) &&
          _insightVisibleSince != null &&
          DateTime.now().difference(_insightVisibleSince!) <
              _kMinInsightDisplay &&
          !severityUp) {
        _schedulePersistResync();
        return;
      }

      _stableLine = raw.insightLine;
      _stableContext = raw.insightContextLine;
      _stableHint = raw.actionHint;
      _feedbackSent = false;

      if (_insightRevealed) {
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
    setState(() {
      if (immediateReveal) {
        _insightRevealed = true;
      } else if (startTimer) {
        _insightRevealed = false;
        final fpCaptured = revealFp;
        _revealTimer = Timer(_kInsightRevealDelay, () {
          if (mounted) {
            setState(() => _insightRevealed = true);
            _insightVisibleSince = DateTime.now();
            _lastVisibleTier = widget.snapshot.stateTier;
            _publishRevealState(fpCaptured, raw);
          }
        });
      }
    });
    if (bumpInsightVisibleSince) {
      _insightVisibleSince = DateTime.now();
      _lastVisibleTier = widget.snapshot.stateTier;
      _publishRevealState(revealFp, raw);
    }
  }

  Future<void> _sendFeedback(FeedbackType type) async {
    if (_feedbackSent) return;
    final narrative = HomeDecisionHeroHelper.build(
      colorScheme: Theme.of(context).colorScheme,
      snapshot: widget.snapshot,
      formatter: widget.formatter,
    );
    final ux = UxDecisionMapper.fromHomeNarrative(
      narrative: narrative,
      tier: widget.snapshot.stateTier,
    );
    final raw = resolveHomeHeroInsight(
      budgetsAsync: widget.budgetsAsync,
      ux: ux,
      formatter: widget.formatter,
      softDeprioritizeBudgetIds: _budgetSoftDepIds,
      rateLimitedBudgetIds: _budgetRateLimitedIds,
    );
    final classKey = homeInsightClassKeyForHero(
      snapshot: widget.snapshot,
      raw: raw,
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
      if (mounted) {
        setState(() => _feedbackSent = true);
        HapticUtils.selection();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    _budgetSoftDepIds =
        ref.watch(budgetHeroSoftDeprioritizeIdsProvider).valueOrNull ?? {};
    _budgetRateLimitedIds = ref.watch(budgetHeroRateLimitedIdsProvider);
    final h = _contentHash();
    if (h != _lastSyncHash) {
      _lastSyncHash = h;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncInsightDisplay());
    }

    final narrative = HomeDecisionHeroHelper.build(
      colorScheme: Theme.of(context).colorScheme,
      snapshot: widget.snapshot,
      formatter: widget.formatter,
    );
    final ux = UxDecisionMapper.fromHomeNarrative(
      narrative: narrative,
      tier: widget.snapshot.stateTier,
    );
    final raw = resolveHomeHeroInsight(
      budgetsAsync: widget.budgetsAsync,
      ux: ux,
      formatter: widget.formatter,
      softDeprioritizeBudgetIds: _budgetSoftDepIds,
      rateLimitedBudgetIds: _budgetRateLimitedIds,
    );
    final fromBudget = raw.budgetProgress != null;
    final toneShort = switch (ux.tone) {
      UxFinancialTone.safe => tr('home.hero.ux.tone_safe_short'),
      UxFinancialTone.watch => tr('home.hero.ux.tone_watch_short'),
      UxFinancialTone.risk => tr('home.hero.ux.tone_risk_short'),
    };

    final displayLine = fromBudget || _insightRevealed
        ? (_stableLine ?? raw.insightLine)
        : toneShort;
    final displayContext =
        (fromBudget || _insightRevealed) ? _stableContext : null;

    final gradient = walletHeroGradientForTone(
      Theme.of(context).colorScheme,
      ux.tone,
    );

    final hint = _stableHint ?? raw.actionHint;

    final hasInsightLine =
        displayLine != null && displayLine.trim().isNotEmpty;
    final String? sourceLabel = fromBudget
        ? (hasInsightLine ? tr('insight.source_budget') : null)
        : (hasInsightLine ? tr('insight.source_behavior') : null);

    final cs = Theme.of(context).colorScheme;
    final subtleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.42),
          height: 1.2,
        );
    final btnSmall = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeLayoutSpacing.s8,
        vertical: HomeLayoutSpacing.s8,
      ),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        homeWalletHeroCard(
          insightLine: displayLine,
          insightContextLine: displayContext,
          budgetProgress: raw.budgetProgress,
          balanceAmountFormatted:
              widget.formatter.format(widget.stats.balance),
          expensesFormatted:
              widget.formatter.format(widget.stats.totalExpenses),
          incomeFormatted:
              widget.formatter.format(widget.stats.totalIncome),
          forecastFormatted: widget.forecastStr,
          gradientColors: gradient,
        )
            .animate()
            .fadeIn(duration: AppMotion.standard, curve: AppMotion.curve)
            .slideY(
              begin: 0.04,
              end: 0,
              duration: AppMotion.screen,
              curve: AppMotion.curve,
            ),
        if (_showSituationImproved)
          Padding(
            padding: const EdgeInsets.only(top: HomeLayoutSpacing.s12),
            child: Text(
              tr('home.hero.ux.situation_improved'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
            ),
          ),
        if (sourceLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: HomeLayoutSpacing.s8),
            child: Text(
              sourceLabel,
              textAlign: TextAlign.center,
              style: subtleStyle,
            ),
          ),
        if (hasInsightLine && !_feedbackSent)
          Padding(
            padding: const EdgeInsets.only(top: HomeLayoutSpacing.s12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('home.hero.ux.feedback_prompt'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.48),
                        height: 1.25,
                      ),
                ),
                SizedBox(height: HomeLayoutSpacing.s8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: btnSmall,
                      onPressed: () => _sendFeedback(FeedbackType.helpful),
                      child: Text(
                        tr('home.hero.ux.feedback_yes'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    TextButton(
                      style: btnSmall,
                      onPressed: () => _sendFeedback(FeedbackType.notHelpful),
                      child: Text(
                        tr('home.hero.ux.feedback_no'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SizedBox(height: HomeLayoutSpacing.s20),
        PrimaryActionButton(
          onPressed: () => context.push('/expenses/new'),
          child: Text(
            tr('home.hero.new_operation'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (hint != null && hint.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: HomeLayoutSpacing.s12),
            child: Text(
              hint.trim(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(
                      alpha: switch (ux.tone) {
                        UxFinancialTone.risk => 0.72,
                        UxFinancialTone.watch => 0.55,
                        UxFinancialTone.safe => 0.38,
                      },
                    ),
                    fontWeight: ux.tone == UxFinancialTone.risk
                        ? FontWeight.w500
                        : FontWeight.w400,
                    height: 1.35,
                  ),
            ),
          ),
      ],
    );
  }
}

/// Скелет градиентной карточки при загрузке.
class _WalletHeroLoadingCard extends StatelessWidget {
  const _WalletHeroLoadingCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 220,
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.4),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Карточка операции в ленте (лёгкая тень, без тяжёлого градиента).
class _HomeFeedCard extends ConsumerWidget {
  const _HomeFeedCard({
    required this.expense,
    required this.formatter,
    required this.showDayHeader,
    required this.dayHeaderText,
  });

  final Expense expense;
  final NumberFormat formatter;
  final bool showDayHeader;
  final String dayHeaderText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isIncome = expense.type.isIncome;
    // Доход — семантика через схему (DESIGN_SYSTEM §5).
    final amountColor = isIncome ? cs.primary : cs.error;
    final timeLabel =
        DateFormat.Hm(context.locale.toLanguageTag())
            .format(expense.occurredAt);

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categoryName = categoriesAsync.maybeWhen(
      data: (cats) {
        final id = expense.categoryId;
        if (id == null) return null;
        for (final c in cats) {
          if (c.id == id) return c.name;
        }
        return null;
      },
      orElse: () => null,
    );

    final title = (expense.note != null && expense.note!.trim().isNotEmpty)
        ? expense.note!.trim()
        : (isIncome ? tr('home.feed.income') : tr('home.feed.expense'));

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: HomeLayoutSpacing.s20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_rounded, color: cs.onError),
      ),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => _deleteExpense(context, ref),
      child: Material(
        color: cs.surface,
        elevation: 2,
        shadowColor: cs.shadow.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/expenses'),
          onLongPress: () => _showContextMenu(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeLayoutSpacing.s16,
              vertical: HomeLayoutSpacing.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDayHeader) ...[
                  Text(
                    dayHeaderText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.35,
                        ),
                  ),
                  SizedBox(height: HomeLayoutSpacing.s12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.payments_outlined
                            : Icons.shopping_cart_outlined,
                        color: amountColor,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: HomeLayoutSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (categoryName != null) ...[
                            SizedBox(height: HomeLayoutSpacing.s8),
                            Text(
                              categoryName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          SizedBox(height: HomeLayoutSpacing.s8),
                          Text(
                            timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '−'}${formatter.format(expense.amount.amount)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: amountColor,
                                letterSpacing: -0.6,
                              ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.3),
                          ),
                          onPressed: () => _showDeleteDialog(context, ref),
                          tooltip: tr('delete'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('expenses.delete.title')),
            content: Text(tr('expenses.delete.message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(tr('delete')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref) async {
    HapticUtils.mediumImpact();
    final repo = ref.read(expensesRepositoryProvider);
    await repo.softDelete(expense.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('expenses.delete.success')),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: tr('expenses.delete.undo'),
            onPressed: () async {
              await repo.upsertExpense(expense.copyWith(
                isDeleted: false,
                deletedAt: null,
              ));
            },
          ),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDelete(context);
    if (confirmed && context.mounted) {
      await _deleteExpense(context, ref);
    }
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isIncome = expense.type.isIncome;
    final amountColor = isIncome ? cs.primary : cs.error;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(
                vertical: HomeLayoutSpacing.s12,
              ),
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: amountColor.withValues(alpha: 0.15),
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: amountColor,
                ),
              ),
              title: Text(
                formatter.format(expense.amount.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              subtitle: Text(
                DateFormat.yMMMMd(context.locale.toLanguageTag())
                    .format(expense.occurredAt),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(tr('expenses.edit.title')),
              onTap: () {
                HapticUtils.selection();
                Navigator.pop(context);
                context.push('/expenses/new', extra: {'expense': expense});
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(tr('expenses.duplicate.title')),
              onTap: () async {
                HapticUtils.selection();
                Navigator.pop(context);
                final repo = ref.read(expensesRepositoryProvider);
                final newExpense = Expense(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: expense.amount,
                  type: expense.type,
                  occurredAt: DateTime.now(),
                  categoryId: expense.categoryId,
                  note: expense.note,
                );
                await repo.upsertExpense(newExpense);
                if (context.mounted) {
                  HapticUtils.success();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('expenses.duplicate.success')),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: cs.error),
              title: Text(
                tr('delete'),
                style: TextStyle(color: cs.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, ref);
              },
            ),
            SizedBox(height: HomeLayoutSpacing.s8),
          ],
        ),
      ),
    );
  }
}
