import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Смягчение пользовательского цвета категории под [ColorScheme] и контраст к фону.
abstract final class CategoryColorHarmony {
  CategoryColorHarmony._();

  /// Цвет иконки: лёгкий lerp к primary + при необходимости подтяжка к [onSurface] по контрасту.
  static Color foreground(Color raw, ColorScheme cs) {
    final blended = Color.lerp(raw, cs.primary, 0.14) ?? raw;
    var result = blended;
    final ratio = _contrastRatio(result, cs.surface);
    if (ratio < 3.0) {
      result = Color.lerp(result, cs.onSurface, 0.42) ?? result;
    } else if (ratio > 11.0) {
      result = Color.lerp(result, cs.onSurface, 0.06) ?? result;
    }
    return result;
  }

  /// Фон под иконкой: тинт согласован с темой, фиксированная прозрачность.
  static Color iconBackgroundTint(Color raw, ColorScheme cs) {
    final base = Color.lerp(raw, cs.primary, 0.09) ?? raw;
    return base.withValues(alpha: 0.13);
  }

  static double _contrastRatio(Color a, Color b) {
    final l1 = _relativeLuminance(a);
    final l2 = _relativeLuminance(b);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// WCAG relative luminance (sRGB).
  static double _relativeLuminance(Color color) {
    double linearize(double channel) {
      return channel <= 0.03928
          ? channel / 12.92
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize(color.r);
    final g = linearize(color.g);
    final b = linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
}
