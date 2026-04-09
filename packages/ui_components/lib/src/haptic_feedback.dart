import 'package:flutter/services.dart';

/// Утилита для haptic feedback
class HapticUtils {
  /// Лёгкая вибрация для обычных действий
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Средняя вибрация для важных действий
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Сильная вибрация для критических действий
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Вибрация при успехе
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Вибрация при ошибке
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  /// Вибрация при выборе
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
