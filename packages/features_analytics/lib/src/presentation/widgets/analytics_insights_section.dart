import 'package:flutter/material.dart';

import '../../providers/smart_insights.dart';

/// Секция умных инсайтов
class AnalyticsInsightsSection extends StatelessWidget {
  const AnalyticsInsightsSection({super.key, required this.insights});

  final List<SmartInsight> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Умные подсказки',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        ...insights.take(3).map((insight) => _InsightCard(insight: insight)),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final SmartInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getIconAndColor(insight.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (insight.trend != null)
              Icon(
                insight.trend == TrendDirection.up
                    ? Icons.arrow_upward
                    : insight.trend == TrendDirection.down
                        ? Icons.arrow_downward
                        : Icons.remove,
                color: insight.trend == TrendDirection.up
                    ? Colors.red
                    : insight.trend == TrendDirection.down
                        ? Colors.green
                        : Colors.grey,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getIconAndColor(InsightType type) {
    switch (type) {
      case InsightType.spending:
        return (Icons.shopping_cart, Colors.blue);
      case InsightType.saving:
        return (Icons.savings, Colors.green);
      case InsightType.trend:
        return (Icons.show_chart, Colors.purple);
      case InsightType.warning:
        return (Icons.warning_amber, Colors.orange);
      case InsightType.achievement:
        return (Icons.emoji_events, Colors.amber);
      case InsightType.pattern:
        return (Icons.auto_graph, Colors.teal);
      case InsightType.tip:
        return (Icons.tips_and_updates, Colors.cyan);
    }
  }
}

