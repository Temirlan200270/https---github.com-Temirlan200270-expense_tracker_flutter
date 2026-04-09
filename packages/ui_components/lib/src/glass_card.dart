import 'dart:ui';

import 'package:flutter/material.dart';

/// Виджет с эффектом размытого стекла (Glassmorphism)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.opacity = 0.2,
    this.blur = 10.0,
    this.borderRadius = 24.0,
  });

  final Widget child;
  final double opacity;
  final double blur;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

