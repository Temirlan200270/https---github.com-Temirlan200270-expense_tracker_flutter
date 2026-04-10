import 'dart:ui';

import 'package:flutter/material.dart';

import 'animated_decision_gradient.dart';

/// Градиент + стекло (Surface 2 decision): общая оболочка для hero и снимка аналитики.
class DecisionGradientShell extends StatelessWidget {
  const DecisionGradientShell({
    super.key,
    required this.gradientColors,
    required this.child,
    this.borderRadius = 28,
    this.blurSigma = 12,
    this.glassAlpha = 0.08,
  });

  /// Минимум три цвета (те же стопы, что у hero на главной).
  final List<Color> gradientColors;
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double glassAlpha;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedDecisionGradient(
              colors: gradientColors,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: glassAlpha * 0.5),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
