import 'package:flutter/material.dart';

import 'haptic_feedback.dart';

/// Вторичная CTA: OutlinedButton, те же высота/радиус/отступы, что у [PrimaryActionButton].
class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.hapticOnPress = true,
    this.height = 56,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final bool hapticOnPress;
  final double height;

  void _onTap() {
    if (hapticOnPress) {
      HapticUtils.selection();
    }
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: Size.fromHeight(height),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: icon == null
          ? OutlinedButton(
              style: style,
              onPressed: onPressed == null ? null : _onTap,
              child: child,
            )
          : OutlinedButton.icon(
              style: style,
              onPressed: onPressed == null ? null : _onTap,
              icon: icon!,
              label: child,
            ),
    );
  }
}
