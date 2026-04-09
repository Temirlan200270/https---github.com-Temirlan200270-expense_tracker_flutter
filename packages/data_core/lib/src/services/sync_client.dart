import 'package:shared_models/shared_models.dart';

import '../errors/data_failure.dart';

abstract class SyncClient {
  Future<void> pushExpenses(List<Expense> expenses);

  Future<List<Expense>> pullExpenses({DateTime? since});
}

abstract class SyncSerializer {
  Map<String, Object?> serializeExpense(Expense expense);

  Expense deserializeExpense(Map<String, Object?> payload);
}

class SyncException extends DataFailure {
  SyncException(super.message, {super.cause});
}

