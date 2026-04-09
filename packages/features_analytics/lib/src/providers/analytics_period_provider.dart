import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AnalyticsPeriod {
  today,
  week,
  month,
  year,
  allTime,
  custom,
}

class AnalyticsPeriodState {
  const AnalyticsPeriodState({
    required this.period,
    this.customFrom,
    this.customTo,
  });

  final AnalyticsPeriod period;
  final DateTime? customFrom;
  final DateTime? customTo;

  AnalyticsPeriodState copyWith({
    AnalyticsPeriod? period,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    return AnalyticsPeriodState(
      period: period ?? this.period,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
    );
  }

  DateTime? get fromDate {
    final now = DateTime.now();
    switch (period) {
      case AnalyticsPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsPeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(weekStart.year, weekStart.month, weekStart.day);
      case AnalyticsPeriod.month:
        return DateTime(now.year, now.month, 1);
      case AnalyticsPeriod.year:
        return DateTime(now.year, 1, 1);
      case AnalyticsPeriod.allTime:
        return null;
      case AnalyticsPeriod.custom:
        return customFrom;
    }
  }

  DateTime? get toDate {
    final now = DateTime.now();
    switch (period) {
      case AnalyticsPeriod.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case AnalyticsPeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
      case AnalyticsPeriod.month:
        final lastDay = DateTime(now.year, now.month + 1, 0);
        return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
      case AnalyticsPeriod.year:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case AnalyticsPeriod.allTime:
        return null;
      case AnalyticsPeriod.custom:
        return customTo;
    }
  }
}

final analyticsPeriodProvider = StateNotifierProvider<AnalyticsPeriodNotifier, AnalyticsPeriodState>((ref) {
  return AnalyticsPeriodNotifier();
});

class AnalyticsPeriodNotifier extends StateNotifier<AnalyticsPeriodState> {
  AnalyticsPeriodNotifier() : super(const AnalyticsPeriodState(period: AnalyticsPeriod.month));

  void setPeriod(AnalyticsPeriod period) {
    state = state.copyWith(period: period);
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(
      period: AnalyticsPeriod.custom,
      customFrom: from,
      customTo: to,
    );
  }
}

