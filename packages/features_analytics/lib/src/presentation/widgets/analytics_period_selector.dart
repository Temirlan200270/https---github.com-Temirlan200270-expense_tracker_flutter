import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/analytics_period_provider.dart';
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Селектор периода для аналитики (Surface 1 + tap).
class AnalyticsPeriodSelector extends ConsumerWidget {
  const AnalyticsPeriodSelector({
    super.key,
    required this.periodState,
  });

  final AnalyticsPeriodState periodState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    String periodLabel;
    switch (periodState.period) {
      case AnalyticsPeriod.today:
        periodLabel = tr('analytics.period.today');
        break;
      case AnalyticsPeriod.week:
        periodLabel = tr('analytics.period.week');
        break;
      case AnalyticsPeriod.month:
        periodLabel = tr('analytics.period.month');
        break;
      case AnalyticsPeriod.year:
        periodLabel = tr('analytics.period.year');
        break;
      case AnalyticsPeriod.allTime:
        periodLabel = tr('analytics.period.all_time');
        break;
      case AnalyticsPeriod.custom:
        final from = periodState.customFrom;
        final to = periodState.customTo;
        if (from != null && to != null) {
          periodLabel =
              '${DateFormat.yMd(context.locale.toLanguageTag()).format(from)} — ${DateFormat.yMd(context.locale.toLanguageTag()).format(to)}';
        } else {
          periodLabel = tr('analytics.period.custom');
        }
        break;
    }

    return AnalyticsSurfaceCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticUtils.selection();
            _showPeriodSelector(context, ref);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AnalyticsLayoutSpacing.s16,
              vertical: AnalyticsLayoutSpacing.s12,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: cs.primary),
                const SizedBox(width: AnalyticsLayoutSpacing.s12),
                Expanded(
                  child: Text(
                    periodLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPeriodSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => const AnalyticsPeriodSelectorSheet(),
    );
  }
}

/// Bottom sheet выбора периода.
class AnalyticsPeriodSelectorSheet extends ConsumerWidget {
  const AnalyticsPeriodSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.watch(analyticsPeriodProvider);

    return SafeArea(
      child: StatefulBuilder(
        builder: (context, setState) {
          AnalyticsPeriod? selected = currentPeriod.period;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AnalyticsLayoutSpacing.s16,
              0,
              AnalyticsLayoutSpacing.s16,
              AnalyticsLayoutSpacing.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('analytics.period_sheet_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AnalyticsLayoutSpacing.s12),
                ...AnalyticsPeriod.values.map((period) {
                  if (period == AnalyticsPeriod.custom) {
                    return RadioListTile<AnalyticsPeriod>(
                      title: Text(_getPeriodLabel(period)),
                      value: period,
                      groupValue: selected,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AnalyticsLayoutSpacing.s8,
                        vertical: 0,
                      ),
                      onChanged: (value) async {
                        setState(() => selected = value);
                        final navigatorContext = context;
                        final from = await showDatePicker(
                          context: navigatorContext,
                          initialDate:
                              currentPeriod.customFrom ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (from != null && navigatorContext.mounted) {
                          final to = await showDatePicker(
                            context: navigatorContext,
                            initialDate: currentPeriod.customTo ?? from,
                            firstDate: from,
                            lastDate: DateTime.now(),
                          );
                          if (to != null) {
                            ref
                                .read(analyticsPeriodProvider.notifier)
                                .setCustomRange(from, to);
                            if (navigatorContext.mounted) {
                              Navigator.pop(navigatorContext);
                            }
                          }
                        }
                      },
                    );
                  }
                  return RadioListTile<AnalyticsPeriod>(
                    title: Text(_getPeriodLabel(period)),
                    value: period,
                    groupValue: selected,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AnalyticsLayoutSpacing.s8,
                      vertical: 0,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selected = value);
                        ref
                            .read(analyticsPeriodProvider.notifier)
                            .setPeriod(value);
                        Navigator.pop(context);
                      }
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getPeriodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return tr('analytics.period.today');
      case AnalyticsPeriod.week:
        return tr('analytics.period.week');
      case AnalyticsPeriod.month:
        return tr('analytics.period.month');
      case AnalyticsPeriod.year:
        return tr('analytics.period.year');
      case AnalyticsPeriod.allTime:
        return tr('analytics.period.all_time');
      case AnalyticsPeriod.custom:
        return tr('analytics.period.custom');
    }
  }
}
