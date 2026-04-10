import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Иконка в блоке инсайта (семантика тона, без хардкода цвета — рисуется поверх градиента).
IconData walletHeroLeadingIconForTone(UxFinancialTone tone) {
  return switch (tone) {
    UxFinancialTone.risk => Icons.warning_rounded,
    UxFinancialTone.watch => Icons.info_outline_rounded,
    UxFinancialTone.safe => Icons.check_circle_outline_rounded,
  };
}

/// Градиент hero под ощущение SAFE / WATCH / RISK (только [ColorScheme], без «кричащего» красного).
List<Color> walletHeroGradientForTone(ColorScheme cs, UxFinancialTone tone) {
  return switch (tone) {
    UxFinancialTone.safe => [
        Color.lerp(cs.primaryContainer, cs.secondaryContainer, 0.35)!,
        Color.lerp(cs.primary, cs.secondary, 0.25)!,
        cs.primary,
      ],
    UxFinancialTone.watch => [
        Color.lerp(cs.tertiaryContainer, cs.surfaceContainerHighest, 0.2)!,
        Color.lerp(cs.tertiary, cs.tertiaryContainer, 0.45)!,
        cs.tertiary,
      ],
    UxFinancialTone.risk => [
        Color.lerp(cs.errorContainer, cs.surfaceContainerHighest, 0.15)!,
        Color.lerp(cs.error, cs.errorContainer, 0.55)!,
        Color.lerp(cs.error, cs.primary, 0.12)!,
      ],
  };
}
