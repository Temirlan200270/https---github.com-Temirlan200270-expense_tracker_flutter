import 'package:flutter/material.dart';

import 'theme/visual_tokens.dart';

/// Surface 1: группировка списков и блоков решений (SSS, DESIGN_SYSTEM §3).
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(SdsRadius.lg),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: SdsStroke.subtle),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SdsRadius.lg),
        child: child,
      ),
    );
  }
}
