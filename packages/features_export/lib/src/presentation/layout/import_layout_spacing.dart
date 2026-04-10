import 'package:flutter/material.dart';

/// Сетка отступов экрана импорта (SSS_UI_SYSTEM_V2 / DESIGN_SYSTEM §12).
abstract final class ImportLayoutSpacing {
  ImportLayoutSpacing._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(s20, s16, s20, s32);
}
