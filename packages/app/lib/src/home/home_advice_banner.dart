import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

import 'home_layout_shell.dart';

/// Карточка «Финансовый совет» / инсайт под hero (loaded и FTUE).
class HomeAdviceBanner extends StatelessWidget {
  const HomeAdviceBanner({
    super.key,
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
      padding: const EdgeInsets.all(SdsSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SdsRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.42),
            cs.tertiaryContainer.withValues(alpha: 0.28),
          ],
        ),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
        ),
        boxShadow: SdsElevation.softCard(cs),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(leadingIcon, color: cs.primary, size: 24),
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
                    borderRadius: BorderRadius.circular(SdsSpacing.xs),
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
    );
  }
}
