import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_providers.dart' show sharedPreferencesProvider;

/// Шаги FTUE-прогрессии на главном экране.
///
/// Каждый шаг — **поведенческое событие**, а не просто UI-флаг.
/// Порядок: welcome → firstExpense → insightSeen → completed.
enum FtueStep {
  /// Пользователь только что прошёл онбординг, 0 операций.
  welcome,

  /// Добавил первую операцию, лента не пуста.
  firstExpense,

  /// Увидел первый инсайт / прогноз в hero.
  insightSeen,

  /// FTUE завершён, больше не показывать onboarding-контент.
  completed,
}

/// Иммутабельное состояние FTUE главного экрана.
@immutable
class HomeFtueState {
  const HomeFtueState({
    required this.step,
    required this.walkthroughSeen,
    this.firstExpenseAt,
  });

  final FtueStep step;

  /// Интерактивный walkthrough overlay уже показан.
  final bool walkthroughSeen;

  /// Момент добавления первой операции (для аналитики / timing).
  final DateTime? firstExpenseAt;

  bool get isFtueActive => step != FtueStep.completed;
  bool get isWelcome => step == FtueStep.welcome;

  HomeFtueState copyWith({
    FtueStep? step,
    bool? walkthroughSeen,
    DateTime? firstExpenseAt,
  }) {
    return HomeFtueState(
      step: step ?? this.step,
      walkthroughSeen: walkthroughSeen ?? this.walkthroughSeen,
      firstExpenseAt: firstExpenseAt ?? this.firstExpenseAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier (persistence + auto-advance)
// ---------------------------------------------------------------------------

class HomeFtueNotifier extends StateNotifier<HomeFtueState> {
  HomeFtueNotifier(this._prefs)
      : super(const HomeFtueState(
          step: FtueStep.welcome,
          walkthroughSeen: false,
        )) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _keyStep = 'ftue_step';
  static const _keyWalkthrough = 'ftue_walkthrough_seen';
  static const _keyFirstExpenseAt = 'ftue_first_expense_at';

  void _load() {
    final stepIndex = _prefs.getInt(_keyStep);
    final step = (stepIndex != null && stepIndex < FtueStep.values.length)
        ? FtueStep.values[stepIndex]
        : FtueStep.welcome;
    final walkthrough = _prefs.getBool(_keyWalkthrough) ?? false;
    final firstExpenseMs = _prefs.getInt(_keyFirstExpenseAt);
    final firstExpenseAt = firstExpenseMs != null
        ? DateTime.fromMillisecondsSinceEpoch(firstExpenseMs)
        : null;

    state = HomeFtueState(
      step: step,
      walkthroughSeen: walkthrough,
      firstExpenseAt: firstExpenseAt,
    );
  }

  /// Переход к следующему шагу (только вперёд, не откатывается).
  Future<void> advanceTo(FtueStep target) async {
    if (target.index <= state.step.index) return;
    state = state.copyWith(step: target);
    await _prefs.setInt(_keyStep, target.index);
  }

  /// Отметить первую операцию (вызывается из провайдера-наблюдателя).
  Future<void> markFirstExpense() async {
    if (state.step.index >= FtueStep.firstExpense.index) return;
    final now = DateTime.now();
    state = state.copyWith(
      step: FtueStep.firstExpense,
      firstExpenseAt: now,
    );
    await _prefs.setInt(_keyStep, FtueStep.firstExpense.index);
    await _prefs.setInt(_keyFirstExpenseAt, now.millisecondsSinceEpoch);
  }

  /// Отметить walkthrough как показанный.
  Future<void> markWalkthroughSeen() async {
    state = state.copyWith(walkthroughSeen: true);
    await _prefs.setBool(_keyWalkthrough, true);
  }

  /// Пропустить FTUE целиком (кнопка «Пропустить» или ручной сброс).
  Future<void> complete() async {
    await advanceTo(FtueStep.completed);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final homeFtueProvider =
    StateNotifierProvider<HomeFtueNotifier, HomeFtueState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HomeFtueNotifier(prefs);
});

