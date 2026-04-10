import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/smart_insights.dart';
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Секция умных инсайтов (Analysis Mode, DESIGN_SYSTEM §7.2).
class AnalyticsInsightsSection extends StatelessWidget {
  const AnalyticsInsightsSection({super.key, required this.insights});

  final List<SmartInsight> insights;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AnalyticsLayoutSpacing.s8),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: cs.primary,
                size: 22,
              ),
              const SizedBox(width: AnalyticsLayoutSpacing.s8),
              Text(
                tr('analytics.insights.title'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        ...insights
            .take(3)
            .map(
              (insight) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AnalyticsLayoutSpacing.s12,
                ),
                child: _InsightCard(insight: insight),
              ),
            ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final SmartInsight insight;

  String _typeLabel() {
    return switch (insight.type) {
      InsightType.spending => tr('analytics.insights.type_spending'),
      InsightType.saving => tr('analytics.insights.type_saving'),
      InsightType.trend => tr('analytics.insights.type_trend'),
      InsightType.warning => tr('analytics.insights.type_warning'),
      InsightType.achievement => tr('analytics.insights.type_achievement'),
      InsightType.pattern => tr('analytics.insights.type_pattern'),
      InsightType.tip => tr('analytics.insights.type_tip'),
    };
  }

  (IconData, InsightChipTone) _iconAndTone() {
    return switch (insight.type) {
      InsightType.spending => (
          Icons.shopping_cart_outlined,
          InsightChipTone.informational,
        ),
      InsightType.saving => (
          Icons.savings_outlined,
          InsightChipTone.positive,
        ),
      InsightType.trend => (
          Icons.show_chart_rounded,
          InsightChipTone.informational,
        ),
      InsightType.warning => (
          Icons.warning_amber_rounded,
          InsightChipTone.caution,
        ),
      InsightType.achievement => (
          Icons.emoji_events_outlined,
          InsightChipTone.positive,
        ),
      InsightType.pattern => (
          Icons.auto_graph_rounded,
          InsightChipTone.neutral,
        ),
      InsightType.tip => (
          Icons.tips_and_updates_outlined,
          InsightChipTone.informational,
        ),
    };
  }

  Color _trendColor(ColorScheme cs) {
    final t = insight.trend;
    if (t == null || t == InsightTrendDirection.stable) {
      return cs.onSurfaceVariant;
    }
    if (t == InsightTrendDirection.up) return cs.error;
    return cs.primary;
  }

  IconData _trendIcon() {
    final t = insight.trend;
    if (t == InsightTrendDirection.up) return Icons.arrow_upward_rounded;
    if (t == InsightTrendDirection.down) {
      return Icons.arrow_downward_rounded;
    }
    return Icons.remove_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (typeIcon, tone) = _iconAndTone();

    return AnalyticsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InsightChip(
                    label: _typeLabel(),
                    icon: typeIcon,
                    tone: tone,
                  ),
                  const SizedBox(height: AnalyticsLayoutSpacing.s8),
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AnalyticsLayoutSpacing.s8),
                  Text(
                    insight.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (insight.trend != null) ...[
              const SizedBox(width: AnalyticsLayoutSpacing.s8),
              Icon(
                _trendIcon(),
                color: _trendColor(cs),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
