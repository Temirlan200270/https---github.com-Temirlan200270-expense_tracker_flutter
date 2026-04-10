import 'package:flutter/foundation.dart';
import 'package:shared_models/shared_models.dart';

import 'home_ftue_state.dart';

/// Флаги кросс-системной консистентности.
///
/// Вычисляются Decision Engine на основании комбинации всех state machine.
/// Виджеты читают только флаги — не принимают решения сами.
@immutable
class HomeConsistencyFlags {
  const HomeConsistencyFlags({
    this.ftueBlocked = false,
    this.ftueBlockReason,
    this.feedSuppressed = false,
    this.insightSuppressed = false,
    this.walkthroughSuppressed = false,
  });

  /// FTUE не может продвинуться дальше текущего шага.
  final bool ftueBlocked;
  final String? ftueBlockReason;

  /// Лента операций скрыта (loading / error / empty).
  final bool feedSuppressed;

  /// Hero-инсайт подавлен (FTUE welcome, ошибка hero).
  final bool insightSuppressed;

  /// Walkthrough overlay подавлен (ошибка, пустой экран).
  final bool walkthroughSuppressed;
}

/// Единый выходной снимок Decision Engine.
///
/// `HomePage` подписывается **только на этот объект** — ни один виджет не должен
/// самостоятельно решать «что показать». Решение принимает engine.
@immutable
class HomeDecision {
  const HomeDecision({
    required this.phase,
    required this.ftue,
    required this.showWalkthrough,
    required this.flags,
    this.debugTransitionCount = 0,
  });

  /// Доминирующая фаза данных экрана.
  final UiScreenPhase phase;

  /// Текущий шаг FTUE (с учётом consistency guards).
  final HomeFtueState ftue;

  /// Показывать ли walkthrough overlay (с учётом consistency guards).
  final bool showWalkthrough;

  /// Вычисленные флаги кросс-системных правил.
  final HomeConsistencyFlags flags;

  /// Количество зафиксированных переходов (для отладки).
  final int debugTransitionCount;

  HomeDecision copyWith({
    UiScreenPhase? phase,
    HomeFtueState? ftue,
    bool? showWalkthrough,
    HomeConsistencyFlags? flags,
    int? debugTransitionCount,
  }) {
    return HomeDecision(
      phase: phase ?? this.phase,
      ftue: ftue ?? this.ftue,
      showWalkthrough: showWalkthrough ?? this.showWalkthrough,
      flags: flags ?? this.flags,
      debugTransitionCount:
          debugTransitionCount ?? this.debugTransitionCount,
    );
  }
}
