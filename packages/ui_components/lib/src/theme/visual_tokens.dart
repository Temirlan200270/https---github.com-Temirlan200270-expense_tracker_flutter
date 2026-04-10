import 'package:flutter/material.dart';

/// Слой 2–4: единая визуальная дисциплина (ритм, радиусы, тень, стекло).
///
/// **Анти-drift:** новые альфы/отступы не вводить в `features_*` «на один экран».
/// Расширять только этот файл ([SdsOnSurface], [SdsStroke], [SdsFill], …).
/// Не заводить параллельные ведра вроде `AppTextOpacity` — только сюда.
///
/// Правила:
/// - отступы только из [SdsSpacing] (сетка **4 pt**);
/// - скругления — [SdsRadius] (**16 / 24** + hero **28**);
/// - тени — [SdsElevation] (один «мягкий» профиль на тип поверхности);
/// - стекло на градиенте — [SdsGlass] (фиксированные alpha, без «чуть-чуть»);
/// - текст на **surface** — [SdsOnSurface]; на **градиенте** — [SdsOnGradient];
///   обводки — [SdsStroke]; заливки поверх surface — [SdsFill].
///
/// Motion: [AppMotion] — те же длительности/кривые по всему приложению.
abstract final class SdsSpacing {
  SdsSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;

  /// Между xl и section (заголовки секций §4).
  static const double xlPlus = 28;

  static const double xxl = 32;

  /// Между крупными секциями на экране.
  static const double section = 40;

  /// Лента над нижней навигацией + FAB.
  static const double navFeed = 56;
}

/// Два основных радиуса для карточек/полей + один для hero-оболочки.
abstract final class SdsRadius {
  SdsRadius._();

  /// Поля ввода, чипы, мини-блоки на градиенте.
  static const double sm = 16;

  /// Основные CTA по DESIGN_SYSTEM.
  static const double md = 20;

  /// Карточки, баннеры советов.
  static const double lg = 24;

  /// Hero / [DecisionGradientShell].
  static const double xl = 28;
}

/// Один тип «мягкой» тени на категорию поверхности (Layer 4).
abstract final class SdsElevation {
  SdsElevation._();

  static Color _shadow(ColorScheme cs, double a) =>
      cs.shadow.withValues(alpha: a);

  /// Hero, крупные градиентные карты.
  static List<BoxShadow> softHero(ColorScheme cs) => [
        BoxShadow(
          color: _shadow(cs, 0.12),
          blurRadius: 28,
          offset: const Offset(0, 14),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: _shadow(cs, 0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// Вторичные карточки, баннеры под hero.
  static List<BoxShadow> softCard(ColorScheme cs) => [
        BoxShadow(
          color: _shadow(cs, 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Компактные тайлы (быстрые действия).
  static List<BoxShadow> softTile(ColorScheme cs) => [
        BoxShadow(
          color: _shadow(cs, 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
}

/// Прозрачность стекла поверх градиента — не подбирать локально.
abstract final class SdsGlass {
  SdsGlass._();

  static const double blurSigma = 12;

  /// Блюр-слой в [DecisionGradientShell] (половинка умножается на 0.5 в шелле).
  static const double heroOverlay = 0.08;

  static const double heroOverlayCompact = 0.04;

  /// Мини-панели метрик на hero.
  static const double statFill = 0.16;
  static const double statBorder = 0.28;
}

/// Иерархия текста на [ColorScheme.onSurface] (не путать с [SdsOnGradient]).
abstract final class SdsOnSurface {
  SdsOnSurface._();

  static const double secondary = 0.72;

  static const double tertiary = 0.45;

}

/// Обводки и разделители ([outline] / [outlineVariant]).
abstract final class SdsStroke {
  SdsStroke._();

  static const double subtle = 0.35;

  static const double medium = 0.4;

  static const double hairline = 0.22;
}

/// Полупрозрачные заливки поверх [surface] (кнопки, круги в шапке).
abstract final class SdsFill {
  SdsFill._();

  static const double surfaceMuted = 0.35;

  /// Мягкая заливка акцентного контейнера (круг под иконкой в empty state).
  static const double soft = 0.3;
}

/// Текст и линии поверх градиента (Layer 2) — не подбирать alpha в фичах.
abstract final class SdsOnGradient {
  SdsOnGradient._();

  static const double label = 0.72;
  static const double muted = 0.65;
  static const double divider = 0.22;
}

/// Уровни Surface (Layer 2 / DESIGN_SYSTEM §3) — только семантика, цвета из [ColorScheme].
abstract final class SdsSurface {
  SdsSurface._();

  static Color surface0(ColorScheme cs) => cs.surfaceContainerLowest;

  static Color surface1(ColorScheme cs) => cs.surfaceContainerHigh;

  static Color surface2(ColorScheme cs) => cs.surfaceContainerHighest;
}

/// Ширина контента пустых/ошибочных состояний (кратно 8).
abstract final class SdsLayout {
  SdsLayout._();

  static const double emptyStateMaxWidth = 416;
}
