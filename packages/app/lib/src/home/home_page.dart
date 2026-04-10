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

import 'home_decision.dart';
import 'home_decision_engine.dart';
import 'home_feed_card.dart';
import 'home_feed_provider.dart';
import 'home_feed_tile_model.dart';
import 'home_ftue_state.dart';
import 'home_ftue_steps.dart';
import 'home_layout_shell.dart';
import 'home_loaded_hero_block.dart';
import 'home_more_sheet.dart';
import 'home_walkthrough_overlay.dart';
import 'home_walkthrough_providers.dart';
import 'home_wallet_shell.dart';

/// Главная страница: тонкая оболочка, вся логика — в фазе [UiScreenPhase] и
/// выделенных виджетах ([HomeLoadedHeroBlock], [HomeFeedCard] и т.д.).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  // ---------------------------------------------------------------------------
  // Header actions
  // ---------------------------------------------------------------------------

  static Widget _headerActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PressableScale(
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: tr('home.more_sheet.tooltip'),
          icon: Icon(Icons.tune_rounded, color: cs.onSurface, size: 22),
          onPressed: () {
            HapticUtils.selection();
            showHomeMoreSheet(context);
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(homeDecisionProvider);
    final feedTiles = ref.watch(homeFeedTilesProvider);

    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    final financialAsync = ref.watch(financialSnapshotProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerLowest,
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(financialSnapshotProvider.future),
                ref.refresh(expensesStreamProvider.future),
                ref.refresh(budgetsWithSpendingProvider.future),
              ]);
            },
            child: _buildBodyForPhase(
              context: context,
              ref: ref,
              formatter: formatter,
              decision: decision,
              financialAsync: financialAsync,
              feedTiles: feedTiles,
            ),
          ),
        ),
        if (decision.showWalkthrough)
          HomeWalkthroughOverlay(
            onDismiss: () {
              ref.read(homeWalkthroughPendingProvider.notifier).clearPending();
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Phase → Widget dispatch (SSS §2.1)
  // ---------------------------------------------------------------------------

  static Widget _buildBodyForPhase({
    required BuildContext context,
    required WidgetRef ref,
    required NumberFormat formatter,
    required HomeDecision decision,
    required AsyncValue<FinancialSnapshot> financialAsync,
    required List<ExpenseTileModel> feedTiles,
  }) {
    switch (decision.phase) {
      case UiScreenPhase.loading:
        return _loadingShell(context);
      case UiScreenPhase.error:
        return _expensesError(context, ref);
      case UiScreenPhase.empty:
        return _emptyLayout(context, formatter, decision.ftue);
      case UiScreenPhase.stale:
      case UiScreenPhase.ready:
      case UiScreenPhase.partial:
      case UiScreenPhase.updating:
        if (decision.flags.feedSuppressed) {
          return _emptyLayout(context, formatter, decision.ftue);
        }
        return _nonEmptyLayout(context, formatter, feedTiles, financialAsync);
    }
  }

  // ---------------------------------------------------------------------------
  // Phase layouts
  // ---------------------------------------------------------------------------

  static Widget _loadingShell(BuildContext context) {
    return HomeLayoutShell(
      physics: const AlwaysScrollableScrollPhysics(),
      header: HomeWalletHeader(topActions: _headerActions(context)),
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WalletHeroLoadingCard(),
          SizedBox(height: HomeLayoutSpacing.s16),
          const SkeletonList(itemCount: 4),
        ],
      ),
    );
  }

  static Widget _expensesError(BuildContext context, WidgetRef ref) {
    return ErrorState(
      title: tr('home.transactions_error'),
      message: tr('error_state.message'),
      action: PrimaryActionButton(
        onPressed: () => ref.invalidate(expensesStreamProvider),
        child: Text(tr('retry')),
      ),
    );
  }

  static List<Color> _ftueGradient(ColorScheme cs) {
    return [
      cs.primary,
      Color.lerp(cs.primary, cs.tertiary, 0.4)!,
      Color.lerp(cs.primary, cs.primaryContainer, 0.3)!,
    ];
  }

  static Widget _emptyLayout(
    BuildContext context,
    NumberFormat formatter,
    HomeFtueState ftue,
  ) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return HomeLayoutShell(
      physics: const AlwaysScrollableScrollPhysics(),
      header: HomeWalletHeader(topActions: _headerActions(context)),
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          homeWalletHeroCard(
            insightLine: null,
            balanceAmountFormatted: formatter.format(0),
            expensesFormatted: formatter.format(0),
            incomeFormatted: formatter.format(0),
            forecastFormatted: tr('home.hero.forecast_na'),
            isCompactFtue: true,
            showMetrics: false,
            subtitle: tr('home.ftue.hero_subtitle'),
            gradientColors: _ftueGradient(cs),
            contentOrder: WalletHeroContentOrder.balanceMetricsInsight,
          )
              .animate()
              .fadeIn(duration: AppMotion.standard, curve: AppMotion.curve)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: AppMotion.screen,
                curve: AppMotion.curve,
              ),
          SizedBox(height: HomeLayoutSpacing.s24),
          PrimaryActionButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              HapticUtils.selection();
              context.push(AppRoutes.expensesNew);
            },
            child: Text(
              tr('home.ftue.primary_cta'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          )
              .animate()
              .fadeIn(
                duration: AppMotion.standard,
                delay: const Duration(milliseconds: 80),
                curve: AppMotion.curve,
              )
              .slideY(
                begin: 0.06,
                end: 0,
                duration: AppMotion.standard,
                delay: const Duration(milliseconds: 80),
                curve: AppMotion.curve,
              ),
          SizedBox(height: HomeLayoutSpacing.s12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticUtils.selection();
                context.push(AppRoutes.import);
              },
              icon: Icon(Icons.upload_file_rounded, size: 18, color: cs.primary),
              label: Text(
                tr('home.ftue.import_cta'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: HomeLayoutSpacing.s32),
          HomeFtueSteps(currentStep: ftue.step),
        ],
      ),
      feedHeader: null,
      feedSlivers: const <Widget>[],
      bottomSpacerHeight: HomeLayoutSpacing.s32,
    );
  }

  static Widget _nonEmptyLayout(
    BuildContext context,
    NumberFormat formatter,
    List<ExpenseTileModel> feedTiles,
    AsyncValue<FinancialSnapshot> financialAsync,
  ) {
    return HomeLayoutShell(
      physics: const AlwaysScrollableScrollPhysics(),
      header: HomeWalletHeader(topActions: _headerActions(context)),
      hero: financialAsync.when(
        data: (fin) {
          final forecastStr = fin.decision.forecast != null
              ? formatter.format(fin.decision.forecast!.projectedExpenses)
              : tr('home.hero.forecast_na');
          return HomeLoadedHeroBlock(
            formatter: formatter,
            stats: fin.decision.monthStats,
            forecastStr: forecastStr,
          );
        },
        loading: () => const WalletHeroLoadingCard(),
        error: (_, __) => ErrorState(
          compact: true,
          title: tr('home.stats_error'),
          action: PrimaryActionButton(
            onPressed: () => context.push(AppRoutes.expensesNew),
            child: Text(
              tr('home.hero.new_operation'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
      feedHeader: SectionHeader(
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
      feedSlivers: [
        SliverPadding(
          padding: HomeLayoutSpacing.feedOuter,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tile = feedTiles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: HomeLayoutSpacing.s12),
                  child: HomeFeedCard(
                    tile: tile,
                    formatter: formatter,
                    showDayHeader: _shouldShowDayHeader(feedTiles, index),
                    dayHeaderText: _dayHeaderText(
                      context,
                      tile.expense.occurredAt,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: AppMotion.standard,
                        delay: AppMotion.staggerInterval * index,
                        curve: AppMotion.curve,
                      )
                      .slideY(
                        begin: 0.06,
                        end: 0,
                        duration: AppMotion.standard,
                        delay: AppMotion.staggerInterval * index,
                        curve: AppMotion.curve,
                      ),
                );
              },
              childCount: feedTiles.length,
            ),
          ),
        ),
      ],
      bottomSpacerHeight: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Feed helpers
  // ---------------------------------------------------------------------------

  static bool _shouldShowDayHeader(List<ExpenseTileModel> tiles, int index) {
    if (index == 0) return true;
    final a = tiles[index - 1].expense.occurredAt;
    final b = tiles[index].expense.occurredAt;
    return a.year != b.year || a.month != b.month || a.day != b.day;
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
