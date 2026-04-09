import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_core/data_core.dart';
import 'package:local_db/local_db.dart';
import 'package:shared_models/shared_models.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_expenses/features_expenses.dart';

/// Провайдер репозитория долгов
final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalDebtsRepository(db);
});

/// Провайдер потока всех долгов
final debtsStreamProvider = StreamProvider.autoDispose<List<Debt>>((ref) {
  final repo = ref.watch(debtsRepositoryProvider);
  return repo.watchDebts();
});

/// Провайдер долгов "Мне должны"
final debtsTheyOweProvider = FutureProvider.autoDispose<List<Debt>>((ref) async {
  final repo = ref.watch(debtsRepositoryProvider);
  return repo.fetchDebtsByType(DebtType.theyOwe);
});

/// Провайдер долгов "Я должен"
final debtsIOweProvider = FutureProvider.autoDispose<List<Debt>>((ref) async {
  final repo = ref.watch(debtsRepositoryProvider);
  return repo.fetchDebtsByType(DebtType.iOwe);
});

/// Контроллер для управления долгами
class DebtsController extends StateNotifier<AsyncValue<void>> {
  DebtsController(
    this._debtsRepo,
    this._expensesRepo,
  ) : super(const AsyncValue.data(null));

  final DebtsRepository _debtsRepo;
  final ExpensesRepository _expensesRepo;

  /// Создать новый долг и автоматически создать транзакцию
  Future<void> createDebt({
    required String personName,
    required Money amount,
    required DebtType type,
    DateTime? dueDate,
    String? comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Создаём запись о долге
      final debt = Debt(
        personName: personName,
        totalAmount: amount,
        type: type,
        dueDate: dueDate,
        comment: comment,
      );
      await _debtsRepo.upsertDebt(debt);

      // 2. Автоматически создаём транзакцию в кошельке
      if (type == DebtType.theyOwe) {
        // Я дал в долг -> У меня расход
        await _expensesRepo.upsertExpense(
          Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: amount,
            type: ExpenseType.expense,
            occurredAt: DateTime.now(),
            note: 'Дал в долг: $personName${comment != null ? ' ($comment)' : ''}',
          ),
        );
      } else {
        // Я взял в долг -> У меня доход (пришли деньги)
        await _expensesRepo.upsertExpense(
          Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: amount,
            type: ExpenseType.income,
            occurredAt: DateTime.now(),
            note: 'Взял в долг у: $personName${comment != null ? ' ($comment)' : ''}',
          ),
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Обновить долг
  Future<void> updateDebt(Debt debt) async {
    state = const AsyncValue.loading();
    try {
      await _debtsRepo.upsertDebt(
        debt.copyWith(updatedAt: DateTime.now().toUtc()),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Погасить долг (частично или полностью)
  Future<void> repayDebt({
    required String debtId,
    required Money amount,
  }) async {
    state = const AsyncValue.loading();
    try {
      final debt = await _debtsRepo.getDebt(debtId);
      if (debt == null) {
        throw Exception('Долг не найден');
      }

      // 1. Обновляем сумму погашения в таблице долгов
      await _debtsRepo.addRepayment(debtId, amount);

      // 2. Создаём транзакцию возврата
      if (debt.type == DebtType.theyOwe) {
        // Мне вернули -> Доход
        await _expensesRepo.upsertExpense(
          Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: amount,
            type: ExpenseType.income,
            occurredAt: DateTime.now(),
            note: 'Возврат долга от: ${debt.personName}',
          ),
        );
      } else {
        // Я вернул -> Расход
        await _expensesRepo.upsertExpense(
          Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: amount,
            type: ExpenseType.expense,
            occurredAt: DateTime.now(),
            note: 'Погашение долга: ${debt.personName}',
          ),
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Удалить долг
  Future<void> deleteDebt(String id) async {
    state = const AsyncValue.loading();
    try {
      await _debtsRepo.softDelete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Провайдер контроллера долгов
final debtsControllerProvider =
    StateNotifierProvider.autoDispose<DebtsController, AsyncValue<void>>((ref) {
  final debtsRepo = ref.watch(debtsRepositoryProvider);
  final expensesRepo = ref.watch(expensesRepositoryProvider);
  return DebtsController(debtsRepo, expensesRepo);
});

