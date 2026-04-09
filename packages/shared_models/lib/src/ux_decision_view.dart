/// Тон состояния для визуала (градиент/акцент), без техно-терминов в тексте.
enum UxFinancialTone {
  safe,
  watch,
  risk,
}

/// Человеческий слой поверх Decision Engine: один смысл, один контекст, одна подсказка к действию.
/// Внутренние метрики (confidence, slope, momentum) сюда не попадают — только уже интерпретированный текст.
class UxDecisionView {
  const UxDecisionView({
    required this.coreMessage,
    required this.actionHint,
    required this.tone,
    this.contextLine,
  });

  /// Доминирующая мысль: что сейчас важно (одна фраза/абзац).
  final String coreMessage;

  /// Короткий второй слой: ситуация / «почему мы так говорим» (например статус tier человеческим языком).
  final String? contextLine;

  /// Мягкая подсказка к поведению (не обязана совпадать с label primary CTA).
  final String actionHint;

  final UxFinancialTone tone;
}
