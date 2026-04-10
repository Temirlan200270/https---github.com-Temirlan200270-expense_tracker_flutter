import 'package:flutter/material.dart';

import 'theme/motion_tokens.dart';

bool decisionGradientTripletEquals(List<Color> a, List<Color> b) {
  if (a.length < 3 || b.length < 3) return false;
  return a[0] == b[0] && a[1] == b[1] && a[2] == b[2];
}

List<Color> decisionGradientTakeTriplet(List<Color> source) {
  if (source.length >= 3) return source.take(3).toList();
  return List<Color>.from(source);
}

/// Плавная смена трёхстопного градиента (смена тона / §5).
class AnimatedDecisionGradient extends StatefulWidget {
  const AnimatedDecisionGradient({
    super.key,
    required this.colors,
    required this.child,
  });

  final List<Color> colors;
  final Widget child;

  @override
  State<AnimatedDecisionGradient> createState() =>
      _AnimatedDecisionGradientState();
}

class _AnimatedDecisionGradientState extends State<AnimatedDecisionGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> _from;
  late List<Color> _to;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.screen,
    );
    final initial = decisionGradientTakeTriplet(widget.colors);
    _from = List<Color>.from(initial);
    _to = List<Color>.from(initial);
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant AnimatedDecisionGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = decisionGradientTakeTriplet(widget.colors);
    if (!decisionGradientTripletEquals(_to, next)) {
      _from = List<Color>.generate(
        3,
        (i) => Color.lerp(_from[i], _to[i], _controller.value)!,
      );
      _to = next;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        final c0 = Color.lerp(_from[0], _to[0], t)!;
        final c1 = Color.lerp(_from[1], _to[1], t)!;
        final c2 = Color.lerp(_from[2], _to[2], t)!;
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c0, c1, c2],
        );
        return CustomPaint(
          painter: _DecisionGradientPainter(gradient: gradient),
          child: widget.child,
        );
      },
    );
  }
}

class _DecisionGradientPainter extends CustomPainter {
  _DecisionGradientPainter({required this.gradient});

  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _DecisionGradientPainter oldDelegate) =>
      oldDelegate.gradient != gradient;
}
