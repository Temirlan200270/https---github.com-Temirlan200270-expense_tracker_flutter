import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

/// Быстрые действия под hero: четыре квадратные кнопки (сетка 4 / [SdsRadius] / одна тень).
class HomeQuickActionGrid extends StatelessWidget {
  const HomeQuickActionGrid({super.key});

  static const double _iconTileExtent = 48;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    Widget tile({
      required IconData icon,
      required Color background,
      required Color iconColor,
      required String label,
      required VoidCallback onTap,
      required int staggerIndex,
    }) {
      return Expanded(
        child: PressableScale(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticUtils.selection();
                onTap();
              },
              borderRadius: BorderRadius.circular(SdsRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SdsSpacing.xxs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _iconTileExtent,
                      height: _iconTileExtent,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(SdsRadius.sm),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                        boxShadow: SdsElevation.softTile(cs),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(height: SdsSpacing.xs),
                    Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.15,
                        color: cs.onSurface.withValues(alpha: 0.88),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
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
            delay: AppMotion.staggerInterval * staggerIndex,
            curve: AppMotion.curve,
          )
          .slideY(
            begin: 0.06,
            end: 0,
            duration: AppMotion.standard,
            delay: AppMotion.staggerInterval * staggerIndex,
            curve: AppMotion.curve,
          );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile(
          icon: Icons.remove_rounded,
          background: cs.primaryContainer.withValues(alpha: 0.72),
          iconColor: cs.primary,
          label: tr('home.cta_grid.expense'),
          staggerIndex: 0,
          onTap: () => context.push(AppRoutes.expensesNew),
        ),
        const SizedBox(width: SdsSpacing.sm),
        tile(
          icon: Icons.add_rounded,
          background: cs.tertiaryContainer.withValues(alpha: 0.75),
          iconColor: cs.tertiary,
          label: tr('home.cta_grid.income'),
          staggerIndex: 1,
          onTap: () =>
              context.push(AppRoutes.expensesNew, extra: {'type': 'income'}),
        ),
        const SizedBox(width: SdsSpacing.sm),
        tile(
          icon: Icons.work_outline_rounded,
          background: cs.secondaryContainer.withValues(alpha: 0.78),
          iconColor: cs.secondary,
          label: tr('home.cta_grid.budget'),
          staggerIndex: 2,
          onTap: () => context.go(AppRoutes.budgets),
        ),
        const SizedBox(width: SdsSpacing.sm),
        tile(
          icon: Icons.bar_chart_rounded,
          background: Color.lerp(
            cs.surfaceContainerHighest,
            cs.primary,
            0.22,
          )!,
          iconColor: cs.primary,
          label: tr('home.cta_grid.analytics'),
          staggerIndex: 3,
          onTap: () => context.go(AppRoutes.analytics),
        ),
      ],
    );
  }
}
