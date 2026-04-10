import 'package:flutter/material.dart';

import 'theme/visual_tokens.dart';

/// Вариант визуала заголовка секции (роли §4 DESIGN_SYSTEM).
enum SectionHeaderVariant {
  /// Роль Title: основной якорь секции.
  standard,

  /// Приглушённый label под hero (низкая плотность, вторичный блок).
  mutedLabel,
}

/// Якорь секции: заголовок + опциональный trailing (кнопка / ссылка).
/// См. DESIGN_SYSTEM §7.2 `SectionHeader`.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
    this.variant = SectionHeaderVariant.standard,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final SectionHeaderVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final TextStyle? titleStyle = switch (variant) {
      SectionHeaderVariant.standard => theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: SdsOnSurface.secondary),
          ),
      SectionHeaderVariant.mutedLabel => theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: cs.onSurface.withValues(alpha: SdsOnSurface.tertiary),
          ),
    };

    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            SdsSpacing.lg,
            SdsSpacing.xlPlus,
            SdsSpacing.lg,
            SdsSpacing.xs,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
