import 'package:shared_models/shared_models.dart';

/// Логирование «полезно / не полезно» для инсайтов.
abstract class InsightFeedbackRepository {
  Future<void> record(InsightFeedback feedback);
}
