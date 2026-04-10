import 'package:flutter/material.dart';

/// Карточка опций импорта: radius 24, `surfaceContainerHigh` (как аналитика).
class ImportSurfaceCard extends StatelessWidget {
  const ImportSurfaceCard({
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
  final Color? backgroundColor;
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
          color: borderColor ?? cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
