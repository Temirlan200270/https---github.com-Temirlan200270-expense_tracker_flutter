import 'package:flutter/material.dart';

/// Семантика состояния: безопасно / внимание / риск (DESIGN_SYSTEM §5).
enum RiskLevel {
  safe,
  caution,
  danger,
}

/// Компактный бейдж состояния на базе контейнеров темы.
class RiskBadge extends StatelessWidget {
  const RiskBadge({
    super.key,
    required this.level,
    required this.label,
  });

  final RiskLevel level;
  final String label;

  (Color bg, Color fg) _colors(ColorScheme cs) {
    return switch (level) {
      RiskLevel.safe => (cs.primaryContainer, cs.onPrimaryContainer),
      RiskLevel.caution => (cs.tertiaryContainer, cs.onTertiaryContainer),
      RiskLevel.danger => (cs.errorContainer, cs.onErrorContainer),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _colors(cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
