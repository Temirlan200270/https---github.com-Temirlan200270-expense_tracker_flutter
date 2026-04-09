import 'package:flutter/material.dart';

/// Плотная строка списка (Action Mode): смысл → деталь → метаданные, trailing справа.
/// См. DESIGN_SYSTEM §7.2, §9.
class CompactRow extends StatelessWidget {
  const CompactRow({
    super.key,
    required this.title,
    this.subtitle,
    this.belowSubtitle,
    this.leadingAccentColor,
    this.leadingAccentWidth = 3,
    this.leadingAccentHeight = 48,
    this.leadingAccentBorderRadius = 2,
    this.leading,
    this.trailing,
    this.compact = false,
    this.padding,
    this.gapAfterAccent = 10,
    this.compactGapAfterAccent = 8,
    this.titleMaxLines,
  });

  final String title;
  final String? subtitle;
  final Widget? belowSubtitle;

  /// Вертикальная полоса слева (например цвет уверенности).
  final Color? leadingAccentColor;
  final double leadingAccentWidth;
  final double leadingAccentHeight;
  final double leadingAccentBorderRadius;

  /// Если задан, заменяет полосу [leadingAccentColor].
  final Widget? leading;
  final Widget? trailing;
  final bool compact;
  final EdgeInsetsGeometry? padding;
  final double gapAfterAccent;
  final double compactGapAfterAccent;
  final int? titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleStyle = compact
        ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);
    final metaStyle = compact
        ? theme.textTheme.labelSmall
            ?.copyWith(color: cs.onSurfaceVariant)
        : theme.textTheme.bodySmall
            ?.copyWith(color: cs.onSurfaceVariant);

    final lines = titleMaxLines ?? (compact ? 1 : 2);
    final gap = compact ? compactGapAfterAccent : gapAfterAccent;

    Widget? start;
    if (leading != null) {
      start = leading;
    } else if (leadingAccentColor != null) {
      start = Container(
        width: leadingAccentWidth,
        height: leadingAccentHeight,
        decoration: BoxDecoration(
          color: leadingAccentColor,
          borderRadius: BorderRadius.circular(leadingAccentBorderRadius),
        ),
      );
    }

    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 6 : 10,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (start != null) ...[
            start,
            SizedBox(width: gap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: compact ? 2 : 4),
                  Text(subtitle!, style: metaStyle),
                ],
                if (belowSubtitle != null) ...[
                  if (compact) const SizedBox(height: 4) else const SizedBox(height: 6),
                  belowSubtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: compact ? 4 : 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
