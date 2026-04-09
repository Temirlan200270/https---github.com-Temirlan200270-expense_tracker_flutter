/// Минимальная обратная связь по показанному инсайту (без ML / обучения).
enum FeedbackType {
  helpful,
  notHelpful,
}

/// Запись в хранилище.
class InsightFeedback {
  const InsightFeedback({
    required this.id,
    required this.insightId,
    required this.timestamp,
    required this.feedbackType,
  });

  final String id;
  final String insightId;
  final DateTime timestamp;
  final FeedbackType feedbackType;
}
