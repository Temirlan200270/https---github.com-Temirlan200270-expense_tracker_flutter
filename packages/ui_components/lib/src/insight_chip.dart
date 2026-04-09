import 'package:flutter/material.dart';

/// Тон инсайта для подложки и текста (семантика §5).
enum InsightChipTone {
  neutral,
  informational,
  positive,
  caution,
  negative,
}

/// Сжатый инсайт: подпись к графику / карточке (Analysis Mode).
class InsightChip extends StatelessWidget {
  const InsightChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = InsightChipTone.neutral,
  });

  final String label;
  final IconData? icon;
  final InsightChipTone tone;

  (Color bg, Color fg, Color border) _palette(ColorScheme cs) {
    return switch (tone) {
      InsightChipTone.neutral => (
          cs.surfaceContainerHighest.withValues(alpha: 0.55),
          cs.onSurface.withValues(alpha: 0.85),
          cs.outline.withValues(alpha: 0.28),
        ),
      InsightChipTone.informational => (
          cs.primaryContainer.withValues(alpha: 0.65),
          cs.onPrimaryContainer,
          cs.primary.withValues(alpha: 0.35),
        ),
      InsightChipTone.positive => (
          cs.primaryContainer.withValues(alpha: 0.5),
          cs.onPrimaryContainer,
          cs.primary.withValues(alpha: 0.3),
        ),
      InsightChipTone.caution => (
          cs.tertiaryContainer.withValues(alpha: 0.65),
          cs.onTertiaryContainer,
          cs.tertiary.withValues(alpha: 0.4),
        ),
      InsightChipTone.negative => (
          cs.errorContainer.withValues(alpha: 0.75),
          cs.onErrorContainer,
          cs.error.withValues(alpha: 0.35),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, border) = _palette(cs);
    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved = (icon != null ? 22.0 : 0) + 20 + 12;
        final maxW = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - reserved).clamp(48.0, 560.0)
            : 200.0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
