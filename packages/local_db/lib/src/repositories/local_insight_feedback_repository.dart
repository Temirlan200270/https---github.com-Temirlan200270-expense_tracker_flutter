import 'package:data_core/data_core.dart';
import 'package:drift/drift.dart';
import 'package:shared_models/shared_models.dart';

import '../database/app_database.dart';

/// Реализация [InsightFeedbackRepository] на Drift.
class LocalInsightFeedbackRepository implements InsightFeedbackRepository {
  LocalInsightFeedbackRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> record(InsightFeedback feedback) async {
    await _db.into(_db.insightFeedbackTable).insert(
          InsightFeedbackTableCompanion.insert(
            id: feedback.id,
            fingerprint: feedback.fingerprint,
            useful: feedback.useful,
            createdAt: feedback.timestamp,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<InsightFeedbackStats> statsForInsightClass(
    String classKey, {
    int withinDays = 14,
  }) async {
    final from = DateTime.now().subtract(Duration(days: withinDays));
    final rows = await (_db.select(_db.insightFeedbackTable)
          ..where((t) => t.fingerprint.equals(classKey))
          ..where((t) => t.createdAt.isBiggerOrEqualValue(from)))
        .get();
    if (rows.isEmpty) {
      return const InsightFeedbackStats(total: 0, notUsefulCount: 0);
    }
    var notUseful = 0;
    for (final r in rows) {
      if (!r.useful) notUseful++;
    }
    return InsightFeedbackStats(total: rows.length, notUsefulCount: notUseful);
  }

  @override
  Future<InsightFeedbackStats> statsForInsightFingerprintPrefix(
    String prefix, {
    int withinDays = 14,
  }) async {
    final from = DateTime.now().subtract(Duration(days: withinDays));
    final rows = await (_db.select(_db.insightFeedbackTable)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(from)))
        .get();
    final matched = rows.where((r) => r.fingerprint.startsWith(prefix)).toList();
    if (matched.isEmpty) {
      return const InsightFeedbackStats(total: 0, notUsefulCount: 0);
    }
    var notUseful = 0;
    for (final r in matched) {
      if (!r.useful) notUseful++;
    }
    return InsightFeedbackStats(
      total: matched.length,
      notUsefulCount: notUseful,
    );
  }
}
