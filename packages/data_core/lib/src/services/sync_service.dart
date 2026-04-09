import 'package:shared_models/shared_models.dart';

abstract class SyncService {
  Future<void> synchronizeExpenses(List<Expense> pending);

  Future<List<Expense>> hydrateRemoteChanges({DateTime? since});
}

