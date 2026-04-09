// Утилиты нечёткого сравнения строк (Левенштейн) для Matching Engine.

/// Расстояние Левенштейна между [a] и [b] (целые символы, Unicode).
int levenshteinDistance(String a, String b) {
  if (identical(a, b)) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final m = a.length;
  final n = b.length;
  var row = List<int>.generate(n + 1, (j) => j);

  for (var i = 1; i <= m; i++) {
    var previous = row[0];
    row[0] = i;
    final ai = a.codeUnitAt(i - 1);
    for (var j = 1; j <= n; j++) {
      final cost = ai == b.codeUnitAt(j - 1) ? 0 : 1;
      final insert = row[j] + 1;
      final delete = row[j - 1] + 1;
      final replace = previous + cost;
      previous = row[j];
      row[j] = insert < delete
          ? (insert < replace ? insert : replace)
          : (delete < replace ? delete : replace);
    }
  }
  return row[n];
}

/// Нормализованная близость в диапазоне [0, 1]: 1 — полное совпадение.
double normalizedLevenshteinSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  final dist = levenshteinDistance(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  return 1.0 - dist / maxLen;
}

/// Токены для сопоставления названий магазинов / заметок.
List<String> tokenizeForCategorization(String input) {
  final trimmed = input.trim().toLowerCase();
  if (trimmed.isEmpty) return const [];

  final re = RegExp(r'\w+', unicode: true);
  final tokens = re
      .allMatches(trimmed)
      .map((m) => m.group(0)!)
      .where((t) => t.length >= 2)
      .toList();

  if (tokens.isEmpty && trimmed.isNotEmpty) {
    return [trimmed];
  }
  return tokens;
}

/// Лучшая схожесть между любым токеном [text] и строкой [keyword] целиком.
double bestTokenToKeywordSimilarity(String text, String keyword) {
  final kw = keyword.trim().toLowerCase();
  if (kw.isEmpty) return 0;

  final tokens = tokenizeForCategorization(text);
  if (tokens.isEmpty) {
    return normalizedLevenshteinSimilarity(text.trim().toLowerCase(), kw);
  }

  var best = 0.0;
  for (final t in tokens) {
    final sim = normalizedLevenshteinSimilarity(t, kw);
    if (sim > best) best = sim;
    if (kw.length >= 3 && t.length >= kw.length && t.contains(kw)) {
      best = best < 1.0 ? 1.0 : best;
    }
  }
  return best;
}

/// Максимальная схожесть между токенами двух фраз (для истории транзакций).
double maxTokenCrossSimilarity(String a, String b) {
  final ta = tokenizeForCategorization(a);
  final tb = tokenizeForCategorization(b);
  if (ta.isEmpty || tb.isEmpty) {
    return normalizedLevenshteinSimilarity(
      a.trim().toLowerCase(),
      b.trim().toLowerCase(),
    );
  }
  var best = 0.0;
  for (final x in ta) {
    for (final y in tb) {
      final sim = normalizedLevenshteinSimilarity(x, y);
      if (sim > best) best = sim;
    }
  }
  return best;
}
