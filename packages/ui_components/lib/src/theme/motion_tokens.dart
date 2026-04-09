import 'package:flutter/material.dart';

/// Именованные тайминги и кривые для единого motion-слоя (Neo-bank).
class AppMotion {
  AppMotion._();

  /// Микро-отклик (тап, иконка).
  static const Duration fast = Duration(milliseconds: 120);

  /// Обычное появление блоков и списков.
  static const Duration standard = Duration(milliseconds: 200);

  /// Переходы экранов (согласовано с GoRouter ~260 ms).
  static const Duration screen = Duration(milliseconds: 280);

  /// Stagger между элементами списка.
  static const Duration staggerInterval = Duration(milliseconds: 30);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve curveReverse = Curves.easeInCubic;
}
