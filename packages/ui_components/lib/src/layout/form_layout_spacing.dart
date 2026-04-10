/// Сетка форм ввода (Action Zone): единые отступы и радиусы полей.
/// См. DESIGN_SYSTEM, SSS_UI_SYSTEM_V2 §1.1.
abstract final class FormLayoutSpacing {
  FormLayoutSpacing._();

  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;

  /// Скругление полей ввода (12–16 по контракту).
  static const double inputRadius = 16;
}
