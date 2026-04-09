import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Глобальная библиотека переиспользуемых анимаций (согласно документации flutter_animate)
class AppAnimations {
  // Базовые эффекты появления
  static final List<Effect> fadeInUp = [
    FadeEffect(
      duration: 300.ms,
      curve: Curves.easeOut,
    ),
    SlideEffect(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
      duration: 300.ms,
      curve: Curves.easeOut,
    ),
  ];

  // Эффект появления с масштабированием (для карточек)
  static final List<Effect> scaleIn = [
    ScaleEffect(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1, 1),
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    ),
    FadeEffect(
      duration: 400.ms,
      curve: Curves.easeOut,
    ),
  ];

  // Эффект для Hero карточек (более драматичный)
  static final List<Effect> heroCard = [
    FadeEffect(
      duration: 500.ms,
      curve: Curves.easeOut,
    ),
    ScaleEffect(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      duration: 500.ms,
      curve: Curves.easeOutCubic,
    ),
  ];

  // Shimmer эффект для загрузки
  static final List<Effect> shimmerLoad = [
    ShimmerEffect(
      duration: 1500.ms,
      color: const Color(0xFF80DDFF),
    ),
  ];

  // Эффект тряски для ошибок
  static final List<Effect> errorShake = [
    ShakeEffect(
      duration: 400.ms,
      hz: 5,
      offset: const Offset(8, 0),
      rotation: 0,
    ),
    TintEffect(
      color: Colors.red,
      end: 0.3,
      duration: 200.ms,
    ),
  ];

  // Эффект для кнопок при нажатии
  static final List<Effect> buttonPress = [
    ScaleEffect(
      begin: const Offset(1, 1),
      end: const Offset(0.95, 0.95),
      duration: 100.ms,
      curve: Curves.easeInOut,
    ),
  ];

  // Эффект для списков (staggered)
  static List<Effect> listItem(int index) {
    return [
      FadeEffect(
        duration: 300.ms,
        delay: (50 * index).ms,
        curve: Curves.easeOut,
      ),
      SlideEffect(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
        duration: 300.ms,
        delay: (50 * index).ms,
        curve: Curves.easeOutCubic,
      ),
    ];
  }

  // Эффект для настроек (slide from right)
  static List<Effect> settingsTile(int index) {
    return [
      FadeEffect(
        duration: 300.ms,
        delay: (30 * index).ms,
        curve: Curves.easeOut,
      ),
      SlideEffect(
        begin: const Offset(0.1, 0),
        end: Offset.zero,
        duration: 300.ms,
        delay: (30 * index).ms,
        curve: Curves.easeOutCubic,
      ),
    ];
  }

  // Эффект для чисел (счетчик)
  static final List<Effect> numberCount = [
    FadeEffect(
      duration: 200.ms,
      curve: Curves.easeOut,
    ),
    ScaleEffect(
      begin: const Offset(1.1, 1.1),
      end: const Offset(1, 1),
      duration: 300.ms,
      curve: Curves.easeOutBack,
    ),
  ];
}

