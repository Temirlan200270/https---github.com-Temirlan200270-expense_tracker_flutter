import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// Текущий мост Behavior → UI (пока нейтральный; движок подставит значения позже).
final uiBehaviorStateProvider = Provider<UiBehaviorState>((ref) {
  return UiBehaviorState.neutral;
});
