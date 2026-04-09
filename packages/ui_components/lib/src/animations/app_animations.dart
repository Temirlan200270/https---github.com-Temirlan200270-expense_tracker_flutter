import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Глобальная библиотека переиспользуемых анимаций (flutter_animate).
/// Тайминги: UI ~150–250 ms, easeOut — ощущение быстрого отклика.
class AppAnimations {
  // Базовые эффекты появления
  static final List<Effect> fadeInUp = [
    FadeEffect(
      duration: 200.ms,
      curve: Curves.easeOutCubic,
    ),
    SlideEffect(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
      duration: 220.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  // Эффект появления с масштабированием (для карточек)
  static final List<Effect> scaleIn = [
    ScaleEffect(
      begin: const Offset(0.92, 0.92),
      end: const Offset(1, 1),
      duration: 240.ms,
      curve: Curves.easeOutCubic,
    ),
    FadeEffect(
      duration: 220.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  // Эффект для Hero карточек (чуть дольше списка, без «театра»)
  static final List<Effect> heroCard = [
    FadeEffect(
      duration: 280.ms,
      curve: Curves.easeOutCubic,
    ),
    ScaleEffect(
      begin: const Offset(0.97, 0.97),
      end: const Offset(1, 1),
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  // Shimmer эффект для загрузки
  static final List<Effect> shimmerLoad = [
    ShimmerEffect(
      duration: 1100.ms,
      color: const Color(0xFF80DDFF),
    ),
  ];

  // Эффект тряски для ошибок
  static final List<Effect> errorShake = [
    ShakeEffect(
      duration: 220.ms,
      hz: 6,
      offset: const Offset(6, 0),
      rotation: 0,
    ),
    TintEffect(
      color: Colors.red,
      end: 0.3,
      duration: 160.ms,
    ),
  ];

  // Эффект для кнопок при нажатии
  static final List<Effect> buttonPress = [
    ScaleEffect(
      begin: const Offset(1, 1),
      end: const Offset(0.97, 0.97),
      duration: 80.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  // Эффект для списков (staggered)
  static List<Effect> listItem(int index) {
    return [
      FadeEffect(
        duration: 180.ms,
        delay: (28 * index).ms,
        curve: Curves.easeOutCubic,
      ),
      SlideEffect(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
        duration: 190.ms,
        delay: (28 * index).ms,
        curve: Curves.easeOutCubic,
      ),
    ];
  }

  // Эффект для настроек (slide from right)
  static List<Effect> settingsTile(int index) {
    return [
      FadeEffect(
        duration: 180.ms,
        delay: (24 * index).ms,
        curve: Curves.easeOutCubic,
      ),
      SlideEffect(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
        duration: 200.ms,
        delay: (24 * index).ms,
        curve: Curves.easeOutCubic,
      ),
    ];
  }

  // Эффект для чисел (счетчик)
  static final List<Effect> numberCount = [
    FadeEffect(
      duration: 160.ms,
      curve: Curves.easeOutCubic,
    ),
    ScaleEffect(
      begin: const Offset(1.06, 1.06),
      end: const Offset(1, 1),
      duration: 200.ms,
      curve: Curves.easeOutCubic,
    ),
  ];
}

