import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'home_event.dart';

/// Запись перехода состояния — ответ на вопрос «почему система это сделала?»
@immutable
class StateTransitionRecord {
  const StateTransitionRecord({
    required this.timestamp,
    required this.trigger,
    required this.from,
    required this.to,
    this.rule,
    this.detail,
  });

  /// Когда произошёл переход.
  final DateTime timestamp;

  /// Событие, инициировавшее переход.
  final HomeEventKind trigger;

  /// Предыдущее состояние (human-readable).
  final String from;

  /// Новое состояние (human-readable).
  final String to;

  /// Какое правило консистентности применилось (null = штатный переход).
  final String? rule;

  /// Произвольная диагностика (что именно изменилось).
  final String? detail;

  @override
  String toString() {
    final r = rule != null ? ' [rule: $rule]' : '';
    final d = detail != null ? ' ($detail)' : '';
    return '[$timestamp] $trigger: $from → $to$r$d';
  }
}

/// Кольцевой буфер переходов. Хранит последние [capacity] записей.
///
/// Доступен для отладки (UI-overlay, dev-tools, логгер).
/// Потокобезопасность не нужна — Dart single-threaded.
class HomeTransitionLog {
  HomeTransitionLog({this.capacity = 64});

  final int capacity;
  final Queue<StateTransitionRecord> _buffer = Queue<StateTransitionRecord>();

  List<StateTransitionRecord> get records => _buffer.toList();
  int get length => _buffer.length;
  bool get isEmpty => _buffer.isEmpty;
  StateTransitionRecord? get last => _buffer.isNotEmpty ? _buffer.last : null;

  void record(StateTransitionRecord r) {
    _buffer.addLast(r);
    while (_buffer.length > capacity) {
      _buffer.removeFirst();
    }
  }

  /// Все переходы, инициированные данным событием.
  List<StateTransitionRecord> forTrigger(HomeEventKind kind) {
    return _buffer.where((r) => r.trigger == kind).toList();
  }

  /// Переходы, в которых сработало правило консистентности.
  List<StateTransitionRecord> guarded() {
    return _buffer.where((r) => r.rule != null).toList();
  }

  void clear() => _buffer.clear();
}
