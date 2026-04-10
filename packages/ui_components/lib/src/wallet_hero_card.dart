import 'package:flutter/material.dart';

import 'decision_gradient_shell.dart';
import 'decision_insight_block.dart';
import 'theme/visual_tokens.dart';

/// Порядок блоков внутри [WalletHeroCard].
enum WalletHeroContentOrder {
  /// Анализ сверху, затем баланс и метрики (историческое поведение).
  classic,

  /// §2.1 Decision Mode: баланс → инсайт → подсказка → метрики → опциональный CTA.
  decision,

  /// Как в продуктовом макете: баланс → три метрики → блок «Анализ» (инсайт) внизу карты.
  balanceMetricsInsight,
}

/// Премиальная hero-карточка кошелька: градиент, стекло, инсайт, баланс, три метрики.
/// Все подписи передаются снаружи (l10n в приложении).
class WalletHeroCard extends StatelessWidget {
  const WalletHeroCard({
    super.key,
    this.insightLine,
    required this.analysisSectionLabel,
    required this.totalBalanceLabel,
    required this.balanceAmountFormatted,
    required this.expensesLabel,
    required this.expensesFormatted,
    required this.incomeLabel,
    required this.incomeFormatted,
    required this.forecastLabel,
    required this.forecastFormatted,
    this.budgetProgress,
    this.isCompactFtue = false,
    this.showMetrics = true,
    this.subtitle,
    this.insightContextLine,
    this.insightHintLine,
    this.gradientColors,
    this.contentOrder = WalletHeroContentOrder.classic,
    this.insightLeadingIcon,
    this.footerCta,
  });

  /// Текст блока анализа; пусто/null — блок скрыт.
  final String? insightLine;

  /// Второй слой под основным инсайтом (короткий контекст без «техно»-метрик).
  final String? insightContextLine;

  /// Третий слой: подсказка к действию (например [UxDecisionView.actionHint]).
  final String? insightHintLine;

  final String analysisSectionLabel;
  final String totalBalanceLabel;
  final String balanceAmountFormatted;
  final String expensesLabel;
  final String expensesFormatted;
  final String incomeLabel;
  final String incomeFormatted;
  final String forecastLabel;
  final String forecastFormatted;

  /// 0..1 — тонкий прогресс под инсайтом (бюджет).
  final double? budgetProgress;

  final bool isCompactFtue;

  /// Скрыть строку метрик (Расходы / Доходы / Прогноз) — для FTUE с нулями.
  final bool showMetrics;

  /// Опциональный subtitle под балансом (FTUE мотивация вместо метрик).
  final String? subtitle;

  /// Если задано (3 цвета), задаёт настроение SAFE/WATCH/RISK; иначе стандартный градиент темы.
  final List<Color>? gradientColors;

  /// Порядок §2.1 vs классический.
  final WalletHeroContentOrder contentOrder;

  /// Иконка семантики тона (из [ColorScheme], логика в приложении).
  final IconData? insightLeadingIcon;

  /// Одна primary CTA внизу карточки (Decision Mode).
  final Widget? footerCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final colors = (gradientColors != null && gradientColors!.length >= 3)
        ? gradientColors!.take(3).toList()
        : <Color>[
            cs.primary,
            Color.lerp(cs.primary, cs.tertiary, 0.45)!,
            Color.lerp(cs.primary, cs.primaryContainer, 0.35)!,
          ];

    final hasInsight =
        insightLine != null && insightLine!.trim().isNotEmpty;
    final hint = insightHintLine?.trim();
    final hasHint = hint != null && hint.isNotEmpty;
    final progress = budgetProgress;

    final balanceBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          totalBalanceLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: SdsOnGradient.label),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: SdsSpacing.xs),
        Text(
          balanceAmountFormatted,
          style: theme.textTheme.displayLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            height: 1.05,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: SdsSpacing.sm),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: SdsOnGradient.label),
              height: 1.35,
            ),
          ),
        ],
      ],
    );

    Widget? insightBlock;
    if (hasInsight) {
      insightBlock = DecisionInsightBlock(
        analysisHeading: analysisSectionLabel,
        insightLine: insightLine!,
        contextLine: insightContextLine,
        hintLine: insightHintLine,
        leadingIcon: insightLeadingIcon,
        budgetProgress: progress,
        bottomSpacing: SdsSpacing.lg,
      );
    }

    final metricsBlock = Column(
      children: [
        Divider(
          height: 1,
          color: Colors.white.withValues(alpha: SdsOnGradient.divider),
        ),
        const SizedBox(height: SdsSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _WalletHeroGlassStat(
                child: _WalletHeroStatColumn(
                  label: expensesLabel,
                  value: expensesFormatted,
                ),
              ),
            ),
            const SizedBox(width: SdsSpacing.xs),
            Expanded(
              child: _WalletHeroGlassStat(
                child: _WalletHeroStatColumn(
                  label: incomeLabel,
                  value: incomeFormatted,
                ),
              ),
            ),
            const SizedBox(width: SdsSpacing.xs),
            Expanded(
              child: _WalletHeroGlassStat(
                child: _WalletHeroStatColumn(
                  label: forecastLabel,
                  value: forecastFormatted,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final List<Widget> columnChildren;
    if (contentOrder == WalletHeroContentOrder.balanceMetricsInsight) {
      columnChildren = [
        balanceBlock,
        if (showMetrics) ...[
          SizedBox(height: isCompactFtue ? SdsSpacing.md : SdsSpacing.xl),
          metricsBlock,
        ],
        if (insightBlock != null) ...[
          SizedBox(height: isCompactFtue ? SdsSpacing.md : SdsSpacing.lg),
          insightBlock,
        ] else if (hasHint) ...[
          SizedBox(height: isCompactFtue ? SdsSpacing.md : SdsSpacing.lg),
          Text(
            hint,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: SdsOnGradient.label),
              height: 1.35,
            ),
          ),
        ],
        if (footerCta != null) ...[
          const SizedBox(height: SdsSpacing.md),
          footerCta!,
        ],
      ];
    } else if (contentOrder == WalletHeroContentOrder.decision) {
      columnChildren = [
        balanceBlock,
        if (insightBlock != null) ...[
          SizedBox(height: isCompactFtue ? SdsSpacing.lg : SdsSpacing.xl),
          insightBlock,
        ] else if (hasHint) ...[
          SizedBox(height: isCompactFtue ? SdsSpacing.lg : SdsSpacing.xl),
          Text(
            hint,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: SdsOnGradient.label),
              height: 1.35,
            ),
          ),
          const SizedBox(height: SdsSpacing.lg),
        ],
        if (showMetrics) ...[
          SizedBox(height: isCompactFtue ? SdsSpacing.md : SdsSpacing.xl),
          metricsBlock,
        ],
        if (footerCta != null) ...[
          const SizedBox(height: SdsSpacing.md),
          footerCta!,
        ],
      ];
    } else {
      columnChildren = [
        if (insightBlock != null) insightBlock,
        balanceBlock,
        if (showMetrics) ...[
          SizedBox(height: isCompactFtue ? SdsSpacing.md : SdsSpacing.xl),
          metricsBlock,
        ],
        if (footerCta != null) ...[
          const SizedBox(height: SdsSpacing.md),
          footerCta!,
        ],
      ];
    }

    return DecisionGradientShell(
      gradientColors: colors,
      glassAlpha:
          isCompactFtue ? SdsGlass.heroOverlayCompact : SdsGlass.heroOverlay,
      child: Padding(
        padding: const EdgeInsets.all(SdsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren,
        ),
      ),
    );
  }
}

/// Полупрозрачная «подкарточка» для метрик на градиенте (макет: мини-стекло).
class _WalletHeroGlassStat extends StatelessWidget {
  const _WalletHeroGlassStat({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: SdsGlass.statFill),
        borderRadius: BorderRadius.circular(SdsRadius.sm),
        border: Border.all(
          color: Colors.white.withValues(alpha: SdsGlass.statBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SdsSpacing.sm),
        child: child,
      ),
    );
  }
}

class _WalletHeroStatColumn extends StatelessWidget {
  const _WalletHeroStatColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: SdsOnGradient.muted),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: SdsSpacing.xxs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
