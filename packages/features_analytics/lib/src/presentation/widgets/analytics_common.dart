import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Секция с анимацией появления (flutter_animate)
class AnimatedAnalyticsSection extends StatelessWidget {
  const AnimatedAnalyticsSection({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 400.ms)
        .slideY(
            begin: 0.1,
            end: 0,
            delay: (index * 50).ms,
            duration: 400.ms,
            curve: Curves.easeOutCubic);
  }
}

/// Карточка загрузки
class AnalyticsLoadingCard extends StatelessWidget {
  const AnalyticsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// Карточка ошибки
class AnalyticsErrorCard extends StatelessWidget {
  const AnalyticsErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

