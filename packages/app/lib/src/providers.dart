import 'package:data_core/data_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_db/local_db.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider инициализируется в bootstrap');
});

final syncClientProvider = Provider<SyncClient>((ref) {
  throw UnimplementedError('syncClientProvider инициализируется в bootstrap');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('syncServiceProvider инициализируется в bootstrap');
});

