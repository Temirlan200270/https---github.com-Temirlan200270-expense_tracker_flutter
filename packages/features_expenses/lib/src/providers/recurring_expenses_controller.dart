import 'package:data_core/data_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../services/recurring_expenses_service.dart';
import 'expenses_providers.dart';

/// Локальные правки поверх [recurringExpensesStreamProvider] (оптимистичный UI).
class RecurringExpensesUiPatch {
  const RecurringExpensesUiPatch({
    this.removedIds = const {},
    this.activeById = const {},
  });

  /// Скрыть строку до подтверждения стримом (удаление).
  final Set<String> removedIds;

  /// Переопределение `isActive` до совпадения со стримом.
  final Map<String, bool> activeById;

  RecurringExpensesUiPatch copyWith({
    Set<String>? removedIds,
    Map<String, bool>? activeById,
  }) {
    return RecurringExpensesUiPatch(
      removedIds: removedIds ?? this.removedIds,
      activeById: activeById ?? this.activeById,
    );
  }
}

bool _sameActiveMap(Map<String, bool> a, Map<String, bool> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

/// Единая точка команд для экрана повторов: репозиторий + сервис, без вызовов из UI.
final recurringExpensesControllerProvider = NotifierProvider.autoDispose<
    RecurringExpensesController, RecurringExpensesUiPatch>(
  RecurringExpensesController.new,
);

/// Список для UI: стрим + оптимистичный патч.
final recurringExpensesDisplayListProvider =
    Provider.autoDispose<List<RecurringExpense>>((ref) {
  final async = ref.watch(recurringExpensesStreamProvider);
  final patch = ref.watch(recurringExpensesControllerProvider);
  return async.maybeWhen(
    data: (list) {
      return list
          .where((e) => !patch.removedIds.contains(e.id))
          .map((e) {
            final o = patch.activeById[e.id];
            if (o != null) return e.copyWith(isActive: o);
            return e;
          })
          .toList();
    },
    orElse: () => const [],
  );
});

class RecurringExpensesController extends AutoDisposeNotifier<RecurringExpensesUiPatch> {
  @override
  RecurringExpensesUiPatch build() {
    ref.listen<AsyncValue<List<RecurringExpense>>>(
      recurringExpensesStreamProvider,
      (_, next) {
        next.whenData(_reconcileWithStream);
      },
      fireImmediately: true,
    );
    return const RecurringExpensesUiPatch();
  }

  RecurringExpensesRepository get _repo =>
      ref.read(recurringExpensesRepositoryProvider);

  RecurringExpensesService get _service =>
      ref.read(recurringExpensesServiceProvider);

  /// Синхронизация патча со стримом: убираем устаревшие ключи.
  void _reconcileWithStream(List<RecurringExpense> list) {
    final inStream = list.map((e) => e.id).toSet();
    final patch = state;

    final cleanedRemoved =
        patch.removedIds.where((id) => inStream.contains(id)).toSet();

    final cleanedActive = <String, bool>{};
    for (final e in list) {
      final want = patch.activeById[e.id];
      if (want != null && want != e.isActive) {
        cleanedActive[e.id] = want;
      }
    }

    if (cleanedRemoved == patch.removedIds &&
        _sameActiveMap(cleanedActive, patch.activeById)) {
      return;
    }

    state = RecurringExpensesUiPatch(
      removedIds: cleanedRemoved,
      activeById: cleanedActive,
    );
  }

  Future<void> toggleActive(RecurringExpense recurring) async {
    final id = recurring.id;
    final next = !recurring.isActive;
    state = state.copyWith(
      activeById: {...state.activeById, id: next},
    );
    try {
      await _repo.upsert(recurring.copyWith(isActive: next));
    } catch (_) {
      final m = Map<String, bool>.from(state.activeById)..remove(id);
      state = state.copyWith(activeById: m);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(
      removedIds: {...state.removedIds, id},
    );
    try {
      await _repo.softDelete(id);
    } catch (_) {
      final s = Set<String>.from(state.removedIds)..remove(id);
      state = state.copyWith(removedIds: s);
      rethrow;
    }
  }

  Future<void> generateNow(RecurringExpense recurring) async {
    await _service.generateExpenseManually(recurring);
    ref.invalidate(expensesStreamProvider);
  }
}
