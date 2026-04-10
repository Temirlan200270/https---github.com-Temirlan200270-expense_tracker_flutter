import 'package:shared_models/shared_models.dart';

/// Логирование «полезно / не полезно» для инсайтов и чтение для понижения confidence.
abstract class InsightFeedbackRepository {
  Future<void> record(InsightFeedback feedback);

  /// Ответы за окно по точному классу инсайта ([InsightFeedback.fingerprint]).
  Future<InsightFeedbackStats> statsForInsightClass(
    String classKey, {
    int withinDays = 14,
  });

  /// Агрегация по префиксу fingerprint (например `v2_b_<id>_` для всех tier).
  Future<InsightFeedbackStats> statsForInsightFingerprintPrefix(
    String prefix, {
    int withinDays = 14,
  });
}
