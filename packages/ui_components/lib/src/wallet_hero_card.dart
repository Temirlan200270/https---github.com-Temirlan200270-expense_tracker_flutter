import 'dart:ui';

import 'package:flutter/material.dart';

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
    this.insightContextLine,
    this.gradientColors,
  });

  /// Текст блока анализа; пусто/null — блок скрыт.
  final String? insightLine;

  /// Второй слой под основным инсайтом (короткий контекст без «техно»-метрик).
  final String? insightContextLine;

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

  /// Если задано (3 цвета), задаёт настроение SAFE/WATCH/RISK; иначе стандартный градиент темы.
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final colors = (gradientColors != null && gradientColors!.length >= 3)
        ? gradientColors!.take(3).toList()
        : <Color>[
            cs.primary,
            Color.lerp(cs.primary, cs.tertiary, 0.35)!,
            cs.primaryContainer,
          ];

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );

    final hasInsight =
        insightLine != null && insightLine!.trim().isNotEmpty;
    final ctx = insightContextLine?.trim();
    final hasContext = ctx != null && ctx.isNotEmpty;
    final progress = budgetProgress;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: isCompactFtue ? 0.04 : 0.08,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasInsight) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 3,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              analysisSectionLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              insightLine!.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (hasContext) ...[
                              const SizedBox(height: 8),
                              Text(
                                ctx,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (progress != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.22),
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  totalBalanceLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  balanceAmountFormatted,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: isCompactFtue ? 18 : 22),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _WalletHeroStatColumn(
                        label: expensesLabel,
                        value: expensesFormatted,
                      ),
                    ),
                    Expanded(
                      child: _WalletHeroStatColumn(
                        label: incomeLabel,
                        value: incomeFormatted,
                      ),
                    ),
                    Expanded(
                      child: _WalletHeroStatColumn(
                        label: forecastLabel,
                        value: forecastFormatted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
            color: Colors.white.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
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
