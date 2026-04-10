import 'package:flutter/material.dart';

import 'theme/motion_tokens.dart';

/// Блок инсайта на градиенте: полоса + иконка + заголовок секции + строки (как на главной).
class DecisionInsightBlock extends StatelessWidget {
  const DecisionInsightBlock({
    super.key,
    required this.analysisHeading,
    required this.insightLine,
    this.contextLine,
    this.hintLine,
    this.leadingIcon,
    this.budgetProgress,
    this.bottomSpacing = 20,
  });

  final String analysisHeading;
  final String insightLine;
  final String? contextLine;
  final String? hintLine;
  final IconData? leadingIcon;
  final double? budgetProgress;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = insightLine.trim();
    if (line.isEmpty) return const SizedBox.shrink();

    final ctx = contextLine?.trim();
    final hasContext = ctx != null && ctx.isNotEmpty;
    final hint = hintLine?.trim();
    final hasHint = hint != null && hint.isNotEmpty;
    final progress = budgetProgress;

    final animatedTexts = AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curveReverse,
      child: KeyedSubtree(
        key: ValueKey('$line|$ctx|$hint|$progress'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analysisHeading,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              line,
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
            if (hasHint) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                  height: 1.35,
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
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            if (leadingIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  leadingIcon,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: animatedTexts),
          ],
        ),
        SizedBox(height: bottomSpacing),
      ],
    );
  }
}
