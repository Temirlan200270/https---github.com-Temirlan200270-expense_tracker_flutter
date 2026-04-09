import 'dart:async';

import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

class MockSyncClient implements SyncClient {
  final _remoteStorage = <String, Expense>{};

  @override
  Future<List<Expense>> pullExpenses({DateTime? since}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (since == null) return _remoteStorage.values.toList();
    return _remoteStorage.values
        .where((expense) => expense.updatedAt == null || expense.updatedAt!.isAfter(since))
        .toList();
  }

  @override
  Future<void> pushExpenses(List<Expense> expenses) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final expense in expenses) {
      _remoteStorage[expense.id] = expense;
    }
  }
}

