// Минимальный мост Behavior Contract → UI (SSS_BEHAVIOR_CONTRACT_V1).
// Движок выставляет значения; виджеты только читают, без дублирования «голоса».

/// Уровень мягкого трения (0 = выкл.; выше — сдвиг акцента CTA/подсказок).
typedef FrictionLevel = double;

/// Снимок для runtime UI: трение, стабильность инсайта, сила подсказок.
class UiBehaviorState {
  const UiBehaviorState({
    this.frictionLevel = 0,
    this.insightStability = 1,
    this.suggestionStrength = 0.5,
  });

  /// 0..1 — насколько ослабить «настойчивость» интерфейса без блокировок.
  final FrictionLevel frictionLevel;

  /// 0..1 — насколько удерживать текущий инсайт (гистерезис / persistence).
  final double insightStability;

  /// 0..1 — сила вторичных подсказок при одном доминирующем нарративе.
  final double suggestionStrength;

  static const UiBehaviorState neutral = UiBehaviorState();

  UiBehaviorState copyWith({
    FrictionLevel? frictionLevel,
    double? insightStability,
    double? suggestionStrength,
  }) {
    return UiBehaviorState(
      frictionLevel: frictionLevel ?? this.frictionLevel,
      insightStability: insightStability ?? this.insightStability,
      suggestionStrength: suggestionStrength ?? this.suggestionStrength,
    );
  }
}
