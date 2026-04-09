import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

class ExampleSyncService implements SyncService {
  ExampleSyncService(this._client);

  final SyncClient _client;

  @override
  Future<List<Expense>> hydrateRemoteChanges({DateTime? since}) {
    return _client.pullExpenses(since: since);
  }

  @override
  Future<void> synchronizeExpenses(List<Expense> pending) {
    return _client.pushExpenses(pending);
  }
}

