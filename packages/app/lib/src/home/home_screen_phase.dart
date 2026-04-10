import 'package:features_analytics/features_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// Единая фаза главного экрана по потоку операций и снимку Decision Engine.
///
/// Правила (SSS §2.1):
/// - `error` — только если недоступен поток операций (критичный источник).
/// - `empty` — валидный ноль операций.
/// - `stale` — перезагрузка потока при уже известном непустом списке.
/// - `partial` — операции есть, снимок финансов ещё грузится или упал (hero отдельно).
/// - `ready` — и лента, и снимок успешны.
UiScreenPhase resolveHomeScreenPhase({
  required AsyncValue<List<Expense>> expenses,
  required AsyncValue<FinancialSnapshot> financial,
  bool refreshInProgress = false,
}) {
  if (refreshInProgress) {
    return UiScreenPhase.updating;
  }

  return expenses.when(
    data: (list) {
      if (list.isEmpty) return UiScreenPhase.empty;
      return financial.when(
        data: (_) => UiScreenPhase.ready,
        loading: () => UiScreenPhase.partial,
        error: (_, __) => UiScreenPhase.partial,
      );
    },
    loading: () {
      final prev = expenses.valueOrNull;
      if (prev == null) return UiScreenPhase.loading;
      if (prev.isEmpty) return UiScreenPhase.empty;
      return UiScreenPhase.stale;
    },
    error: (_, __) => UiScreenPhase.error,
  );
}
