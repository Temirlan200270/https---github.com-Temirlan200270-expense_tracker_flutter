import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_analytics/features_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import 'home_advice_banner.dart';
import 'home_layout_shell.dart';
import 'home_quick_action_grid.dart';
import 'home_wallet_shell.dart';

/// Hero: только UI; логика стабилизации инсайта — [homeHeroInsightNotifierProvider].
class HomeLoadedHeroBlock extends ConsumerStatefulWidget {
  const HomeLoadedHeroBlock({
    super.key,
    required this.formatter,
    required this.stats,
    required this.forecastStr,
  });

  final NumberFormat formatter;
  final AnalyticsStats stats;
  final String forecastStr;

  @override
  ConsumerState<HomeLoadedHeroBlock> createState() =>
      _HomeLoadedHeroBlockState();
}

class _HomeLoadedHeroBlockState extends ConsumerState<HomeLoadedHeroBlock> {
  final GlobalKey _walletHeroCardKey = GlobalKey();

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
  void didUpdateWidget(covariant HomeLoadedHeroBlock oldWidget) {
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
          child: const HomeQuickActionGrid(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: HomeLayoutSpacing.s12),
          child: HomeAdviceBanner(
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

/// Скелет градиентной карточки при загрузке — градиент + мягкая пульсация.
class WalletHeroLoadingCard extends StatelessWidget {
  const WalletHeroLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withValues(alpha: 0.15),
              cs.primaryContainer.withValues(alpha: 0.25),
              cs.tertiary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cs.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: const Duration(milliseconds: 1800),
          color: cs.primary.withValues(alpha: 0.06),
        );
  }
}
