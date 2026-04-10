import 'package:flutter/material.dart';

import 'haptic_feedback.dart';
import 'theme/visual_tokens.dart';
import 'pressable_scale.dart';

/// Круглая кнопка с лёгкой обводкой (шапка neo-bank / референс-макеты).
class OutlinedCircleIconButton extends StatelessWidget {
  const OutlinedCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: SdsSpacing.sm),
      child: PressableScale(
        child: Material(
          color: cs.surfaceContainerHighest.withValues(alpha: SdsFill.surfaceMuted),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            tooltip: tooltip,
            onPressed: () {
              HapticUtils.selection();
              onPressed();
            },
            icon: Icon(icon, size: 22),
            style: IconButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(
                color: cs.outline.withValues(alpha: SdsStroke.hairline),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
