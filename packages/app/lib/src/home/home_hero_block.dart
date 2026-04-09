import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// Объединённый hero главной: состояние + баланс месяца + главная CTA (Decision Mode).
class HomeHeroBlock extends StatelessWidget {
  const HomeHeroBlock({
    super.key,
    required this.topBar,
    required this.stateTitle,
    required this.microAction,
    required this.balanceLabel,
    required this.balanceAmount,
    required this.accentColor,
    required this.onPrimaryAction,
    required this.primaryActionLabel,
    this.detailLine,
    this.secondaryAction,
  });

  /// Верхняя строка: меню, аналитика и т.д.
  final Widget topBar;

  final String stateTitle;
  final String microAction;
  final String balanceLabel;
  final String balanceAmount;
  final Color accentColor;
  final VoidCallback onPrimaryAction;
  final String primaryActionLabel;

  /// Синтез / лид инсайта / тренд (один блок вторичного смысла).
  final String? detailLine;

  /// Например, вторичная CTA при FTUE (импорт).
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topInset + 8,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topBar,
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stateTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            microAction,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          if (detailLine != null && detailLine!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detailLine!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            balanceLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balanceAmount,
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -1.5,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () {
                HapticUtils.mediumImpact();
                onPrimaryAction();
              },
              child: Text(
                primaryActionLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (secondaryAction != null) ...[
            const SizedBox(height: 12),
            Center(child: secondaryAction!),
          ],
        ],
      ),
    );
  }
}
