import 'package:flutter/material.dart';

import 'haptic_feedback.dart';

/// Единая главная CTA на экране: FilledButton, высота 56, скругление 20.
/// См. DESIGN_SYSTEM §7.2 `PrimaryActionButton`.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.hapticOnPress = true,
    this.height = 56,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool hapticOnPress;

  /// По умолчанию 56 (главная); для нижних панелей (импорт и т.п.) можно 52.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(height),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed == null
            ? null
            : () {
                if (hapticOnPress) {
                  HapticUtils.mediumImpact();
                }
                onPressed!();
              },
        child: child,
      ),
    );
  }
}
