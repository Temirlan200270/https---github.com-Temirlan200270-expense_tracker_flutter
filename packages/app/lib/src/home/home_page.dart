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
import 'home_walkthrough_overlay.dart';
import 'home_walkthrough_providers.dart';
import 'home_wallet_shell.dart';

/// Сетка 2×2 под hero: расход, доход, импорт, категории (без дублирования нижней панели).
class _HomeQuickActionGrid extends StatelessWidget {
  const _HomeQuickActionGrid();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget tile({
      required Color background,
      required IconData icon,
      required Color iconColor,
      required String label,
      required VoidCallback onTap,
      int staggerIndex = 0,
    }) {
      return Expanded(
        child: PressableScale(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: HomeLayoutSpacing.s8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                    SizedBox(height: HomeLayoutSpacing.s8),
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(
            duration: AppMotion.standard,
            delay: Duration(
              milliseconds: 40 * staggerIndex,
            ),
            curve: AppMotion.curve,
          )
          .scale(
            begin: const Offset(0.94, 0.94),
            duration: AppMotion.standard,
            delay: Duration(
              milliseconds: 40 * staggerIndex,
            ),
            curve: AppMotion.curve,
          );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile(
          background: cs.primaryContainer.withValues(alpha: 0.9),
          icon: Icons.add_rounded,
          iconColor: cs.primary,
          label: tr('home.cta_grid.expense'),
          staggerIndex: 0,
          onTap: () {
            HapticUtils.selection();
            context.push(AppRoutes.expensesNew);
          },
        ),
        tile(
          background: cs.tertiaryContainer.withValues(alpha: 0.85),
          icon: Icons.trending_up_rounded,
          iconColor: cs.tertiary,
          label: tr('home.cta_grid.income'),
          staggerIndex: 1,
          onTap: () {
            HapticUtils.selection();
            context.push(AppRoutes.expensesNew, extra: {'type': 'income'});
          },
        ),
        tile(
          background: cs.secondaryContainer.withValues(alpha: 0.75),
          icon: Icons.upload_file_rounded,
          iconColor: cs.secondary,
          label: tr('home.cta_grid.import'),
          staggerIndex: 2,
          onTap: () {
            HapticUtils.selection();
            context.push(AppRoutes.import);
          },
        ),
        tile(
          background: cs.surfaceContainerHighest.withValues(alpha: 0.95),
          icon: Icons.category_rounded,
          iconColor: cs.primary,
          label: tr('home.cta_grid.categories'),
          staggerIndex: 3,
          onTap: () {
            HapticUtils.selection();
            context.push(AppRoutes.categories);
          },
        ),
      ],
    );
  }
}

/// Карточка «Финансовый совет» под сеткой быстрых действий (как в макете).
class _HomeAdviceBanner extends StatelessWidget {
  const _HomeAdviceBanner({
    required this.title,
    required this.body,
    this.subtitle,
    this.hintLine,
    this.budgetProgress,
    this.leadingIcon = Icons.auto_awesome_rounded,
  });

  final String title;
  final String body;
  final String? subtitle;
  final String? hintLine;
  final double? budgetProgress;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final t = body.trim();
    final h = hintLine?.trim() ?? '';
    if (t.isEmpty &&
        (subtitle == null || subtitle!.trim().isEmpty) &&
        h.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(leadingIcon, color: cs.primary, size: 26),
          SizedBox(width: HomeLayoutSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (t.isNotEmpty) ...[
                  SizedBox(height: HomeLayoutSpacing.s8),
                  Text(
                    t,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.88),
                      height: 1.35,
                    ),
                  ),
                ],
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  SizedBox(height: HomeLayoutSpacing.s8),
                  Text(
                    subtitle!.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.58),
                      height: 1.35,
                    ),
                  ),
                ],
                if (h.isNotEmpty) ...[
                  SizedBox(height: HomeLayoutSpacing.s8),
                  Text(
                    h,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.primary.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
                if (budgetProgress != null) ...[
                  SizedBox(height: HomeLayoutSpacing.s12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: budgetProgress!.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: cs.surface.withValues(alpha: 0.5),
                      color: cs.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppMotion.standard, curve: AppMotion.curve)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: AppMotion.screen,
          curve: AppMotion.curve,
        );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Нижний sheet вместо PopupMenu: тот же набор маршрутов, стиль SSS.
  static void _showHomeMoreSheet(BuildContext context) {
    showSssModalSheet<void>(
      context: context,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        void go(String route) {
          Navigator.of(sheetContext).pop();
          Future.microtask(() {
            if (context.mounted) context.push(route);
          });
        }

        Widget sectionLabel(String key) {
          return Padding(
            padding: const EdgeInsets.only(bottom: HomeLayoutSpacing.s8),
            child: Text(
              tr(key),
              style: Theme.of(sheetContext).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.35,
                  ),
            ),
          );
        }

        Widget divider() {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: HomeLayoutSpacing.s8),
            child: Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          );
        }

        return SssSheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('home.more_sheet.title'),
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(height: HomeLayoutSpacing.s12),
              sectionLabel('home.more_sheet.section_finance'),
              _HomeSheetAction(
                icon: Icons.account_balance_wallet_rounded,
                label: tr('budget.title'),
                foregroundColor: cs.primary,
                onTap: () => go(AppRoutes.budgets),
              ),
              _HomeSheetAction(
                icon: Icons.account_balance_rounded,
                label: tr('debts.title'),
                foregroundColor: cs.primary,
                onTap: () => go(AppRoutes.debts),
              ),
              _HomeSheetAction(
                icon: Icons.category_rounded,
                label: tr('categories.title'),
                foregroundColor: cs.primary,
                onTap: () => go(AppRoutes.categories),
              ),
              _HomeSheetAction(
                icon: Icons.repeat_rounded,
                label: tr('recurring.title'),
                foregroundColor: cs.primary,
                onTap: () => go(AppRoutes.recurring),
              ),
              divider(),
              sectionLabel('home.more_sheet.section_data'),
              _HomeSheetAction(
                icon: Icons.upload_file_rounded,
                label: tr('export.title'),
                foregroundColor: cs.primary,
                onTap: () => go(AppRoutes.export),
              ),
              _HomeSheetAction(
                icon: Icons.download_rounded,
                label: tr('import.title'),
                foregroundColor: cs.primary,
                onTap: () => go(AppRoutes.import),
              ),
              divider(),
              sectionLabel('home.more_sheet.section_app'),
              _HomeSheetAction(
                icon: Icons.settings_rounded,
                label: tr('settings'),
                foregroundColor: cs.primary,
                onTap: () => go(AppRoutes.settings),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _headerActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedCircleIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: tr('analytics.title'),
          // Вкладки shell — только go(), иначе push ломает ветку и экран не виден.
          onPressed: () => context.go(AppRoutes.analytics),
        ),
        Padding(
          padding: const EdgeInsets.only(left: HomeLayoutSpacing.s12),
          child: PressableScale(
            child: Material(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: tr('home.more_sheet.tooltip'),
                icon: Icon(Icons.tune_rounded, color: cs.onSurface, size: 22),
                onPressed: () {
                  HapticUtils.selection();
                  _showHomeMoreSheet(context);
                },
              ),
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
    final showHomeWalkthrough = ref.watch(homeWalkthroughPendingProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
                          insightLine: null,
                          balanceAmountFormatted: formatter.format(0),
                          expensesFormatted: formatter.format(0),
                          incomeFormatted: formatter.format(0),
                          forecastFormatted: tr('home.hero.forecast_na'),
                          isCompactFtue: true,
                          contentOrder:
                              WalletHeroContentOrder.balanceMetricsInsight,
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
                        const _HomeQuickActionGrid(),
                        SizedBox(height: HomeLayoutSpacing.s12),
                        _HomeAdviceBanner(
                          title: tr('home.advice.title'),
                          body: tr('home.hero.ftue_micro'),
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
                          stats: fin.decision.monthStats,
                          forecastStr: forecastStr,
                        );
                      },
                      loading: () => const _WalletHeroLoadingCard(),
                      error: (_, __) => ErrorState(
                        compact: true,
                        title: tr('home.stats_error'),
                        action: PrimaryActionButton(
                          onPressed: () => context.push(AppRoutes.expensesNew),
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
                      ),
                    ),
              feedHeader: globalEmpty
                  ? null
                  : SectionHeader(
                      variant: SectionHeaderVariant.mutedLabel,
                      title: tr('home.feed.recent_upper'),
                      trailing: TextButton(
                        onPressed: () => context.go(AppRoutes.expenses),
                        child: Text(
                          tr('home.feed.all_link'),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
          error: (error, _) => ErrorState(
            title: tr('home.transactions_error'),
            message: tr('error_state.message'),
            action: PrimaryActionButton(
              onPressed: () => ref.invalidate(expensesStreamProvider),
              child: Text(tr('retry')),
            ),
          ),
        ),
      ),
        ),
        if (showHomeWalkthrough)
          HomeWalkthroughOverlay(
            onDismiss: () {
              ref.read(homeWalkthroughPendingProvider.notifier).clearPending();
            },
          ),
      ],
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

/// Hero: только UI; логика стабилизации инсайта — [homeHeroInsightNotifierProvider].
class _HomeLoadedHeroBlock extends ConsumerStatefulWidget {
  const _HomeLoadedHeroBlock({
    required this.formatter,
    required this.stats,
    required this.forecastStr,
  });

  final NumberFormat formatter;
  final AnalyticsStats stats;
  final String forecastStr;

  @override
  ConsumerState<_HomeLoadedHeroBlock> createState() =>
      _HomeLoadedHeroBlockState();
}

class _HomeLoadedHeroBlockState extends ConsumerState<_HomeLoadedHeroBlock> {
  final GlobalKey _walletHeroCardKey = GlobalKey();

  /// Подача темы/формата в [HomeHeroInsightNotifier] вне [build] (без side-effect в build).
  void _syncFormattingToInsightNotifier() {
    ref.read(homeHeroInsightNotifierProvider.notifier).setFormattingContext(
          colorScheme: Theme.of(context).colorScheme,
          formatter: widget.formatter,
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFormattingToInsightNotifier();
  }

  @override
  void didUpdateWidget(covariant _HomeLoadedHeroBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final localeChanged = oldWidget.formatter.locale != widget.formatter.locale;
    final currencyChanged =
        oldWidget.formatter.currencySymbol != widget.formatter.currencySymbol;
    if (localeChanged || currencyChanged) {
      _syncFormattingToInsightNotifier();
    }
  }

  @override
  Widget build(BuildContext context) {
    final insightState = ref.watch(homeHeroInsightNotifierProvider);

    final resolved = insightState.resolved;
    final ux = resolved?.ux;
    final raw = resolved?.raw;

    final tone = ux?.tone ?? UxFinancialTone.safe;
    final gradient = walletHeroGradientForTone(
      Theme.of(context).colorScheme,
      tone,
    );

    final fromBudget = raw?.budgetProgress != null;
    final toneShort = switch (tone) {
      UxFinancialTone.safe => tr('home.hero.ux.tone_safe_short'),
      UxFinancialTone.watch => tr('home.hero.ux.tone_watch_short'),
      UxFinancialTone.risk => tr('home.hero.ux.tone_risk_short'),
    };

    final displayLine = raw == null
        ? toneShort
        : (fromBudget || insightState.insightRevealed)
            ? (insightState.stableLine ?? raw.insightLine)
            : toneShort;
    final displayContext = (fromBudget || insightState.insightRevealed)
        ? insightState.stableContext
        : null;

    final hint = insightState.stableHint ?? raw?.actionHint;
    final hintTrimmed = (hint ?? '').trim();
    final insightHintForCard =
        hintTrimmed.isNotEmpty ? hintTrimmed : null;

    final hasInsightLine =
        displayLine != null && displayLine.trim().isNotEmpty;
    final String? sourceLabel = raw == null
        ? null
        : (fromBudget
            ? (hasInsightLine ? tr('insight.source_budget') : null)
            : (hasInsightLine ? tr('insight.source_behavior') : null));
    final showFeedbackRow =
        resolved != null && hasInsightLine && !insightState.feedbackSent;

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

    final heroCard = homeWalletHeroCard(
      key: _walletHeroCardKey,
      insightLine: null,
      insightContextLine: null,
      insightHintLine: null,
      budgetProgress: null,
      balanceAmountFormatted: widget.formatter.format(widget.stats.balance),
      expensesFormatted:
          widget.formatter.format(widget.stats.totalExpenses),
      incomeFormatted: widget.formatter.format(widget.stats.totalIncome),
      forecastFormatted: widget.forecastStr,
      gradientColors: gradient,
      contentOrder: WalletHeroContentOrder.balanceMetricsInsight,
      insightLeadingIcon: null,
    );

    final heroWrapped = insightState.heroEnterAnimationPlayed
        ? heroCard
        : heroCard
            .animate(
              onComplete: (_) {
                ref
                    .read(homeHeroInsightNotifierProvider.notifier)
                    .markHeroEnterAnimationPlayed();
              },
            )
            .fadeIn(duration: AppMotion.standard, curve: AppMotion.curve)
            .slideY(
              begin: 0.04,
              end: 0,
              duration: AppMotion.screen,
              curve: AppMotion.curve,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heroWrapped,
        Padding(
          padding: const EdgeInsets.only(top: HomeLayoutSpacing.s16),
          child: const _HomeQuickActionGrid(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: HomeLayoutSpacing.s12),
          child: _HomeAdviceBanner(
            title: tr('home.advice.title'),
            body: (displayLine ?? '').trim(),
            subtitle: displayContext?.trim(),
            hintLine: insightHintForCard,
            budgetProgress: raw?.budgetProgress,
            leadingIcon: hasInsightLine
                ? walletHeroLeadingIconForTone(tone)
                : Icons.auto_awesome_rounded,
          ),
        ),
        if (insightState.showSituationImproved)
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
        if (showFeedbackRow)
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
                      onPressed: () => ref
                          .read(homeHeroInsightNotifierProvider.notifier)
                          .sendFeedback(FeedbackType.helpful),
                      child: Text(
                        tr('home.hero.ux.feedback_yes'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    TextButton(
                      style: btnSmall,
                      onPressed: () => ref
                          .read(homeHeroInsightNotifierProvider.notifier)
                          .sendFeedback(FeedbackType.notHelpful),
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
      ],
    );
  }
}

/// Строка действия в bottom sheet ленты (без ListTile).
class _HomeSheetAction extends StatelessWidget {
  const _HomeSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = foregroundColor ?? cs.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeLayoutSpacing.s20,
            vertical: HomeLayoutSpacing.s12,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: fg),
              SizedBox(width: HomeLayoutSpacing.s16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
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

/// Карточка операции в ленте: плоский surface, свайп и long-press на удаление,
/// [PressableScale], цвет категории через [CategoryColorHarmony].
class _HomeFeedCard extends ConsumerStatefulWidget {
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
  ConsumerState<_HomeFeedCard> createState() => _HomeFeedCardState();
}

class _HomeFeedCardState extends ConsumerState<_HomeFeedCard> {
  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final cs = Theme.of(context).colorScheme;
    final isIncome = expense.type.isIncome;
    final amountColor = isIncome ? cs.tertiary : cs.error;
    final timeLabel =
        DateFormat.Hm(context.locale.toLanguageTag())
            .format(expense.occurredAt);

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final category = categoriesAsync.maybeWhen(
      data: (cats) {
        final id = expense.categoryId;
        if (id == null) return null;
        for (final c in cats) {
          if (c.id == id) return c;
        }
        return null;
      },
      orElse: () => null,
    );
    final categoryName = category?.name;

    final title = (expense.note != null && expense.note!.trim().isNotEmpty)
        ? expense.note!.trim()
        : (isIncome ? tr('home.feed.income') : tr('home.feed.expense'));

    final cat = category;
    final rawCat = cat != null ? Color(cat.colorValue) : null;
    final iconBg = rawCat != null
        ? CategoryColorHarmony.iconBackgroundTint(rawCat, cs)
        : amountColor.withValues(alpha: 0.12);
    final iconFg =
        rawCat != null ? CategoryColorHarmony.foreground(rawCat, cs) : amountColor;
    final iconData = cat != null
        ? CategoryVisuals.iconForCategory(
            categoryId: cat.id,
            isExpenseCategory: cat.kind.isExpense,
            name: cat.name,
          )
        : (isIncome
            ? Icons.payments_outlined
            : Icons.receipt_long_outlined);

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
      onDismissed: (direction) => _deleteExpense(context),
      child: PressableScale(
        child: EnhancedExpenseCard(
            margin: EdgeInsets.zero,
            gradient: null,
            color: cs.surface,
            onTap: () {
              HapticUtils.selection();
              context.go(AppRoutes.expenses);
            },
            onLongPress: () => _showContextMenu(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeLayoutSpacing.s16,
                vertical: HomeLayoutSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showDayHeader) ...[
                    Text(
                      widget.dayHeaderText,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.35,
                          ),
                    ),
                    SizedBox(height: HomeLayoutSpacing.s12),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          iconData,
                          color: iconFg,
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
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isIncome ? '+' : '−'} ${widget.formatter.format(expense.amount.amount)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: amountColor,
                                  letterSpacing: -0.6,
                                ),
                          ),
                          Text(
                            timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: cs.onSurface
                                      .withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w500,
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

  Future<void> _deleteExpense(BuildContext context) async {
    HapticUtils.mediumImpact();
    final repo = ref.read(expensesRepositoryProvider);
    await repo.softDelete(widget.expense.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('expenses.delete.success')),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: tr('expenses.delete.undo'),
            onPressed: () async {
              await repo.upsertExpense(widget.expense.copyWith(
                isDeleted: false,
                deletedAt: null,
              ));
            },
          ),
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await _confirmDelete(context);
    if (confirmed && context.mounted) {
      await _deleteExpense(context);
    }
  }

  void _showContextMenu(BuildContext context) {
    final expense = widget.expense;
    final cs = Theme.of(context).colorScheme;
    final isIncome = expense.type.isIncome;
    final amountColor = isIncome ? cs.primary : cs.error;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HomeLayoutSpacing.s20,
              HomeLayoutSpacing.s8,
              HomeLayoutSpacing.s20,
              HomeLayoutSpacing.s12,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: amountColor.withValues(alpha: 0.15),
                  child: Icon(
                    isIncome
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: amountColor,
                  ),
                ),
                SizedBox(width: HomeLayoutSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.formatter.format(expense.amount.amount),
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: amountColor,
                            ),
                      ),
                      Text(
                        DateFormat.yMMMMd(sheetContext.locale.toLanguageTag())
                            .format(expense.occurredAt),
                        style: Theme.of(sheetContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _HomeSheetAction(
            icon: Icons.edit_rounded,
            label: tr('expenses.edit.title'),
            onTap: () {
              HapticUtils.selection();
              Navigator.pop(sheetContext);
              context.push(AppRoutes.expensesNew, extra: {'expense': expense});
            },
          ),
          _HomeSheetAction(
            icon: Icons.copy_rounded,
            label: tr('expenses.duplicate.title'),
            onTap: () async {
              HapticUtils.selection();
              Navigator.pop(sheetContext);
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
          _HomeSheetAction(
            icon: Icons.delete_outline_rounded,
            label: tr('delete'),
            foregroundColor: cs.error,
            onTap: () {
              Navigator.pop(sheetContext);
              _showDeleteDialog(context);
            },
          ),
          SizedBox(height: HomeLayoutSpacing.s8),
        ],
      ),
    );
  }
}
