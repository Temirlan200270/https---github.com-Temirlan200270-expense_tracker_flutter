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

/// Градиент hero под ощущение SAFE / WATCH / RISK — насыщенный, не бледный.
List<Color> walletHeroGradientForTone(ColorScheme cs, UxFinancialTone tone) {
  return switch (tone) {
    UxFinancialTone.safe => [
        cs.primary,
        Color.lerp(cs.primary, cs.tertiary, 0.35)!,
        Color.lerp(cs.primary, cs.primaryContainer, 0.3)!,
      ],
    UxFinancialTone.watch => [
        cs.tertiary,
        Color.lerp(cs.tertiary, cs.primary, 0.3)!,
        Color.lerp(cs.tertiary, cs.tertiaryContainer, 0.35)!,
      ],
    UxFinancialTone.risk => [
        cs.error,
        Color.lerp(cs.error, cs.tertiary, 0.25)!,
        Color.lerp(cs.error, cs.errorContainer, 0.4)!,
      ],
  };
}
