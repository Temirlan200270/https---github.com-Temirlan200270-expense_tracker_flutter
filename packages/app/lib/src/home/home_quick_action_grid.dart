import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

import 'home_layout_shell.dart';

/// Сетка 2×2 под hero: расход, доход, импорт, категории.
class HomeQuickActionGrid extends StatelessWidget {
  const HomeQuickActionGrid({super.key});

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
                padding: const EdgeInsets.symmetric(
                  vertical: HomeLayoutSpacing.s8,
                ),
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
            delay: Duration(milliseconds: 40 * staggerIndex),
            curve: AppMotion.curve,
          )
          .scale(
            begin: const Offset(0.94, 0.94),
            duration: AppMotion.standard,
            delay: Duration(milliseconds: 40 * staggerIndex),
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
