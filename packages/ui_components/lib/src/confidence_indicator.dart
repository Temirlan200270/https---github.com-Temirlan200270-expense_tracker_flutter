import 'package:flutter/material.dart';

/// Пороги по умолчанию согласованы с импортом (`kPendingImportLowConfidence` ≈ 0.7).
abstract final class ConfidencePalette {
  /// Цвет акцента для шкалы уверенности 0..1.
  static Color accentColor(
    ThemeData theme, {
    required double confidence,
    double highThreshold = 0.9,
    double midThreshold = 0.7,
  }) {
    final cs = theme.colorScheme;
    if (confidence >= highThreshold) return cs.primary;
    if (confidence >= midThreshold) return cs.tertiary;
    return cs.error;
  }
}

/// Одна точка уверенности (Analysis / review), цвет из [ConfidencePalette].
class ConfidenceDot extends StatelessWidget {
  const ConfidenceDot({
    super.key,
    required this.confidence,
    this.size = 8,
    this.highThreshold = 0.9,
    this.midThreshold = 0.7,
  });

  final double confidence;
  final double size;
  final double highThreshold;
  final double midThreshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ConfidencePalette.accentColor(
          Theme.of(context),
          confidence: confidence,
          highThreshold: highThreshold,
          midThreshold: midThreshold,
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}
