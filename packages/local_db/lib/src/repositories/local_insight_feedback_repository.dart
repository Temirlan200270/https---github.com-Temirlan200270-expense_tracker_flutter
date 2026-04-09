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
            insightId: feedback.insightId,
            feedbackType: feedback.feedbackType == FeedbackType.helpful ? 0 : 1,
            createdAt: feedback.timestamp,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
