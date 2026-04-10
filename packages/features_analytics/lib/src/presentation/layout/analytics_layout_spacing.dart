import 'package:flutter/material.dart';

/// Вертикальный и горизонтальный ритм экрана аналитики (SSS_UI_SYSTEM_V2 §4.1).
abstract final class AnalyticsLayoutSpacing {
  AnalyticsLayoutSpacing._();

  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  /// Отступы скролла: горизонт 20, верх/низ по сетке.
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(s20, s16, s20, s32);

  /// Между крупными секциями в Column.
  static const double sectionGap = s20;
}
