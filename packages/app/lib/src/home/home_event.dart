import 'package:flutter/foundation.dart';

/// Семантическое событие, которое может повлиять на состояние Home-экрана.
///
/// Не хранит payload — это маркер «что произошло», а не «что в данных».
/// Данные берутся из провайдеров в момент обработки.
enum HomeEventKind {
  /// Поток операций изменился (загрузка, данные, ошибка).
  expensesChanged,

  /// Снимок Decision Engine (financial) изменился.
  financialChanged,

  /// FTUE-шаг продвинулся (автоматически или вручную).
  ftueAdvanced,

  /// Hero-инсайт стал видимым (insightRevealed → true).
  insightRevealed,

  /// Walkthrough overlay показан или скрыт.
  walkthroughToggled,

  /// Pull-to-refresh запущен / завершён.
  refreshCycled,

  /// Пользователь принудительно пропустил FTUE.
  ftueSkipped,

  /// Начальная инициализация (первый build).
  initialBuild,
}

/// Конкретное событие с временной меткой.
@immutable
class HomeEvent {
  const HomeEvent(this.kind, {DateTime? timestamp})
      : timestamp = timestamp ?? null;

  final HomeEventKind kind;
  final DateTime? timestamp;

  DateTime get at => timestamp ?? DateTime.now();

  @override
  String toString() => 'HomeEvent($kind @ $at)';
}
