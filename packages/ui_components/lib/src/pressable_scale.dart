import 'package:flutter/material.dart';

/// Единый press-feedback: лёгкий scale (SSS / neo-bank).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
