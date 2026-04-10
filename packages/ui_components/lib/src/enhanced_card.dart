import 'package:flutter/material.dart';

/// Улучшенная карточка с тенями и градиентами
class EnhancedExpenseCard extends StatelessWidget {
  const EnhancedExpenseCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.gradient,
    this.elevation = 2,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final LinearGradient? gradient;
  final double elevation;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardColor;
    final shadow = theme.colorScheme.shadow;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? cardColor : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: 0.08),
            blurRadius: 8 * elevation,
            offset: Offset(0, 2 * elevation),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: shadow.withValues(alpha: 0.04),
            blurRadius: 4 * elevation,
            offset: Offset(0, 1 * elevation),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}

/// Градиент карточки дохода из [ColorScheme] (без произвольных Material shades).
abstract final class IncomeGradient {
  IncomeGradient._();

  static LinearGradient fromScheme(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.primaryContainer.withValues(alpha: 0.55),
          cs.primaryContainer.withValues(alpha: 0.92),
          cs.surface,
        ],
      );
}

/// Градиент карточки расхода из [ColorScheme].
abstract final class ExpenseGradient {
  ExpenseGradient._();

  static LinearGradient fromScheme(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.errorContainer.withValues(alpha: 0.45),
          cs.errorContainer.withValues(alpha: 0.88),
          cs.surface,
        ],
      );
}

/// Градиент по цвету категории; [surface] — целевой «белый» край (обычно [ColorScheme.surface]).
class CategoryGradient extends LinearGradient {
  CategoryGradient(Color color, Color surface)
      : super(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
            surface,
          ],
        );
}
