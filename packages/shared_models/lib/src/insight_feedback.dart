/// Минимальная обратная связь по показанному инсайту (без ML / обучения).
enum FeedbackType {
  helpful,
  notHelpful,
}

/// Статистика по классу инсайта (префикс [InsightFeedback.fingerprint]).
class InsightFeedbackStats {
  const InsightFeedbackStats({required this.total, required this.notUsefulCount});

  final int total;
  final int notUsefulCount;

  double get notUsefulRatio => total == 0 ? 0 : notUsefulCount / total;
}

/// Запись в хранилище: [fingerprint] — класс инсайта (v2_…), [useful] — замыкание в движок.
class InsightFeedback {
  const InsightFeedback({
    required this.id,
    required this.fingerprint,
    required this.useful,
    required this.timestamp,
  });

  final String id;
  /// Версионированный ключ: тип + область + severity (без «голого» текста).
  final String fingerprint;
  final bool useful;
  final DateTime timestamp;
}
