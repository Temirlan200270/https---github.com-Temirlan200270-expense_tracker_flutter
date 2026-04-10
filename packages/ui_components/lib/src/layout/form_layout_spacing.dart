import '../theme/visual_tokens.dart';

/// Сетка форм ввода (Action Zone): единые отступы и радиусы полей.
/// См. DESIGN_SYSTEM, SSS_UI_SYSTEM_V2 §1.1 и [SdsSpacing] / [SdsRadius].
abstract final class FormLayoutSpacing {
  FormLayoutSpacing._();

  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;

  /// Скругление полей ввода — [SdsRadius.sm].
  static const double inputRadius = SdsRadius.sm;
}
