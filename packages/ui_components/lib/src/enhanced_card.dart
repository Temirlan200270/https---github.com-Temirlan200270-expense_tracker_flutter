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
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? cardColor : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8 * elevation,
            offset: Offset(0, 2 * elevation),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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

/// Градиент для карточек доходов
class IncomeGradient extends LinearGradient {
  IncomeGradient()
      : super(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.green.shade100.withOpacity(0.3),
            Colors.white,
          ],
        );
}

/// Градиент для карточек расходов
class ExpenseGradient extends LinearGradient {
  ExpenseGradient()
      : super(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade50,
            Colors.red.shade100.withOpacity(0.3),
            Colors.white,
          ],
        );
}

/// Градиент для категорий
class CategoryGradient extends LinearGradient {
  CategoryGradient(Color color)
      : super(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
            Colors.white,
          ],
        );
}

