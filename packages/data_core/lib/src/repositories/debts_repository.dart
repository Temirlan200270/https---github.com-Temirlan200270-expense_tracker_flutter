import 'package:shared_models/shared_models.dart';

/// Абстрактный репозиторий для работы с долгами
abstract class DebtsRepository {
  /// Получить поток всех активных долгов
  Stream<List<Debt>> watchDebts();

  /// Получить все активные долги
  Future<List<Debt>> fetchDebts();

  /// Получить долги по типу
  Future<List<Debt>> fetchDebtsByType(DebtType type);

  /// Получить долг по ID
  Future<Debt?> getDebt(String id);

  /// Создать или обновить долг
  Future<void> upsertDebt(Debt debt);

  /// Увеличить сумму погашения
  Future<void> addRepayment(String id, Money amount);

  /// Мягкое удаление долга
  Future<void> softDelete(String id, {DateTime? deletedAt});
}

