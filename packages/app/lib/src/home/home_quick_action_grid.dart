import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

/// Компактная строка быстрых действий под hero — pill-кнопки с иконками.
class HomeQuickActionGrid extends StatelessWidget {
  const HomeQuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget pill({
      required IconData icon,
      required Color accentColor,
      required String label,
      required VoidCallback onTap,
      int staggerIndex = 0,
      bool filled = false,
    }) {
      // Контраст: слабый tint + явная обводка (иначе «белое на белом» на светлой теме).
      final bg = filled
          ? Color.lerp(cs.surfaceContainerHighest, accentColor, 0.28)!
          : cs.surfaceContainerHighest;
      final border = BorderSide(
        color: filled
            ? accentColor.withValues(alpha: 0.42)
            : cs.outlineVariant.withValues(alpha: 0.55),
      );

      return Expanded(
        child: PressableScale(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticUtils.selection();
                onTap();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border.color, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accentColor, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.92),
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
          .slideY(
            begin: 0.08,
            end: 0,
            duration: AppMotion.standard,
            delay: Duration(milliseconds: 40 * staggerIndex),
            curve: AppMotion.curve,
          );
    }

    return Row(
      children: [
        pill(
          icon: Icons.remove_rounded,
          accentColor: cs.primary,
          label: tr('home.cta_grid.expense'),
          staggerIndex: 0,
          filled: true,
          onTap: () => context.push(AppRoutes.expensesNew),
        ),
        const SizedBox(width: 8),
        pill(
          icon: Icons.add_rounded,
          accentColor: cs.tertiary,
          label: tr('home.cta_grid.income'),
          staggerIndex: 1,
          filled: true,
          onTap: () =>
              context.push(AppRoutes.expensesNew, extra: {'type': 'income'}),
        ),
        const SizedBox(width: 8),
        pill(
          icon: Icons.upload_file_rounded,
          accentColor: cs.secondary,
          label: tr('home.cta_grid.import'),
          staggerIndex: 2,
          onTap: () => context.push(AppRoutes.import),
        ),
        const SizedBox(width: 8),
        pill(
          icon: Icons.category_rounded,
          accentColor: cs.onSurfaceVariant,
          label: tr('home.cta_grid.categories'),
          staggerIndex: 3,
          onTap: () => context.push(AppRoutes.categories),
        ),
      ],
    );
  }
}
