import 'package:flutter/material.dart';

/// Surface 1 для аналитики: radius 24, `surfaceContainerHigh`, без произвольных цветов (DESIGN_SYSTEM §3).
class AnalyticsSurfaceCard extends StatelessWidget {
  const AnalyticsSurfaceCard({
    super.key,
    required this.child,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;

  /// По умолчанию [ColorScheme.surfaceContainerHigh].
  final Color? backgroundColor;

  /// По умолчанию `outlineVariant` с alpha.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: margin,
      elevation: 0,
      color: backgroundColor ?? cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: borderColor ??
              cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
