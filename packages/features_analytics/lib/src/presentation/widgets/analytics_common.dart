import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ui_components/ui_components.dart';

import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Секция с анимацией появления (токены [AppMotion], DESIGN_SYSTEM §6).
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
    final delay = AppMotion.staggerInterval * index;
    return child
        .animate()
        .fadeIn(
          delay: delay,
          duration: AppMotion.standard,
          curve: AppMotion.curve,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          delay: delay,
          duration: AppMotion.standard,
          curve: AppMotion.curve,
        );
  }
}

/// Карточка-заглушка при загрузке блока аналитики (Surface 1).
class AnalyticsLoadingCard extends StatelessWidget {
  const AnalyticsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnalyticsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ошибка блока: семантика через схему (DESIGN_SYSTEM §5), без сырых Material red.
class AnalyticsErrorCard extends StatelessWidget {
  const AnalyticsErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnalyticsSurfaceCard(
      backgroundColor: cs.errorContainer,
      borderColor: cs.error.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.onErrorContainer),
            const SizedBox(width: AnalyticsLayoutSpacing.s12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
