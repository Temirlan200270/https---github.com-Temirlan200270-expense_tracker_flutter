import 'package:flutter/material.dart';

import 'theme/motion_tokens.dart';

// ignore_for_file: public_member_api_docs

/// Режим экрана по DESIGN_SYSTEM §2 + SSS_UI_SYSTEM_V2 (не дублировать «режим в голове»).
enum SssScreenMode {
  /// Главная: один hero, один CTA.
  decision,

  /// Импорт, review, массовые решения.
  action,

  /// Аналитика: графики, сравнения.
  analysis,

  /// Настройки, справочники.
  configuration,
}

/// Примитивы Material, которые по умолчанию **не** используем во фичах (обёртки — в пакете ui_components).
enum SssUiPrimitive {
  listTile,
  rawScaffold,
  materialCard,
  alertDialog,
  rawMaterial,
}

/// Профиль движения: привязка к [AppMotion], без произвольных длительностей.
enum SssMotionProfile {
  /// Hero, лента, стандартный stagger.
  decision,

  /// Плотные списки, быстрый отклик.
  action,

  /// Секции графиков, меньше slide.
  analysis,

  /// Спокойно, без лишнего motion.
  configuration,
}

/// Контракт экрана: режим + запреты/разрешения + motion-профиль.
///
/// Использование: передать в [PrimaryScaffold.contract]; дочерние виджеты читают через [SssScreenContractScope.of].
class SssScreenContract {
  const SssScreenContract({
    required this.mode,
    required this.motion,
    this.allowedPrimitives = const {},
    this.forbiddenPrimitives = const {},
  });

  /// Не задан явно — без дополнительных ограничений (постепенная миграция).
  static const SssScreenContract unspecified = SssScreenContract(
    mode: SssScreenMode.configuration,
    motion: SssMotionProfile.configuration,
  );

  /// Home, decision hero.
  static const SssScreenContract decision = SssScreenContract(
    mode: SssScreenMode.decision,
    motion: SssMotionProfile.decision,
    forbiddenPrimitives: {
      SssUiPrimitive.listTile,
    },
  );

  /// Импорт, review, bulk.
  static const SssScreenContract action = SssScreenContract(
    mode: SssScreenMode.action,
    motion: SssMotionProfile.action,
    forbiddenPrimitives: {
      SssUiPrimitive.listTile,
      SssUiPrimitive.materialCard,
    },
  );

  /// Аналитика.
  static const SssScreenContract analysis = SssScreenContract(
    mode: SssScreenMode.analysis,
    motion: SssMotionProfile.analysis,
    forbiddenPrimitives: {
      SssUiPrimitive.listTile,
    },
  );

  /// Настройки, категории (списки на SettingsTile / Surface).
  static const SssScreenContract configuration = SssScreenContract(
    mode: SssScreenMode.configuration,
    motion: SssMotionProfile.configuration,
    forbiddenPrimitives: {
      SssUiPrimitive.listTile,
    },
  );

  final SssScreenMode mode;
  final SssMotionProfile motion;

  /// Явный whitelist (если непустой — трактуется как доп. ограничение в будущих проверках).
  final Set<SssUiPrimitive> allowedPrimitives;

  /// Запречённые примитивы для данного режима (документированный контракт).
  final Set<SssUiPrimitive> forbiddenPrimitives;

  /// Рекомендуемая длительность «экранного» акцента по профилю.
  Duration get preferredScreenMotionDuration {
    switch (motion) {
      case SssMotionProfile.decision:
        return AppMotion.screen;
      case SssMotionProfile.action:
        return AppMotion.standard;
      case SssMotionProfile.analysis:
        return AppMotion.standard;
      case SssMotionProfile.configuration:
        return AppMotion.fast;
    }
  }
}

/// Доступ к контракту в поддереве [PrimaryScaffold].
class SssScreenContractScope extends InheritedWidget {
  const SssScreenContractScope({
    super.key,
    required this.contract,
    required super.child,
  });

  final SssScreenContract contract;

  static SssScreenContract? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SssScreenContractScope>()
        ?.contract;
  }

  static SssScreenContract of(BuildContext context) {
    return maybeOf(context) ?? SssScreenContract.unspecified;
  }

  @override
  bool updateShouldNotify(SssScreenContractScope oldWidget) {
    return oldWidget.contract != contract;
  }
}
