// Утилиты нечёткого сравнения строк для Matching Engine (Левенштейн + Dice из string_similarity).

import 'package:string_similarity/string_similarity.dart';

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

/// Стоп-слова из банковских выписок (Kaspi и др.): не магазин, а шум терминала.
const Set<String> kStatementStopWords = {
  'kaspi',
  'gold',
  'qr',
  'transfer',
  'trf',
  'purchase',
  'payment',
  'pay',
  'retail',
  'pos',
  'p2p',
  'www',
  'com',
  'net',
  'http',
  'https',
  'mcc',
  'txn',
  'trn',
  'ref',
  'auth',
  'visa',
  'mc',
  'mastercard',
  'debit',
  'credit',
  'acquiring',
  'terminal',
  'ecom',
  'online',
};

/// Убирает токены из [kStatementStopWords] (регистронезависимо), склеивает остальное пробелами.
String removeStatementStopWordTokens(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;

  final wordRe = RegExp(r'[\w\u0400-\u04FF]+', unicode: true);
  final kept = <String>[];
  for (final m in wordRe.allMatches(trimmed)) {
    final w = m.group(0)!;
    if (!kStatementStopWords.contains(w.toLowerCase())) {
      kept.add(w);
    }
  }
  return kept.join(' ').trim();
}

/// Очистка названия перед fuzzy: шум из выписок и терминалов.
String sanitizeTitleForMatch(String input) {
  var s = input.trim();
  if (s.isEmpty) return s;

  s = s.replaceAll(RegExp(r'\*+'), ' ');
  s = s.replaceAll(RegExp(r'\bMCC\b', caseSensitive: false), ' ');
  s = s.replaceAll(
    RegExp(
      r'\b(?:KZT|USD|EUR|RUB|GBP|KGS|UZS|BYN|TRY|CNY)\b',
      caseSensitive: false,
    ),
    ' ',
  );
  s = s.replaceAll(RegExp(r'№\s*\d+', caseSensitive: false), ' ');
  s = s.replaceAll(RegExp(r'#\s*\d+'), ' ');
  s = s.replaceAll(RegExp(r'\bAlmaty\b', caseSensitive: false), ' ');
  s = s.replaceAll(RegExp(r'\b\d{8,}\b'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  s = removeStatementStopWordTokens(s);
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// Рейтинг схожести: max(Левенштейн, Dice) в нижнем регистре.
double combinedStringRating(String a, String b) {
  final la = a.trim().toLowerCase();
  final lb = b.trim().toLowerCase();
  if (la.isEmpty || lb.isEmpty) return 0;
  final lev = normalizedLevenshteinSimilarity(la, lb);
  final dice = StringSimilarity.compareTwoStrings(la, lb);
  return lev > dice ? lev : dice;
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

/// Лучший рейтинг между токенами [text] и ключевым словом [keyword].
double bestTokenToKeywordSimilarity(String text, String keyword) {
  final kw = keyword.trim().toLowerCase();
  if (kw.isEmpty) return 0;

  final tokens = tokenizeForCategorization(text);
  if (tokens.isEmpty) {
    return combinedStringRating(text, kw);
  }

  var best = 0.0;
  for (final t in tokens) {
    final sim = combinedStringRating(t, kw);
    if (sim > best) best = sim;
    if (kw.length >= 3 && t.length >= kw.length && t.contains(kw)) {
      best = best < 1.0 ? 1.0 : best;
    }
  }
  return best;
}

/// Максимальный рейтинг между токенами двух фраз (история транзакций).
double maxTokenCrossSimilarity(String a, String b) {
  final ta = tokenizeForCategorization(a);
  final tb = tokenizeForCategorization(b);
  if (ta.isEmpty || tb.isEmpty) {
    return combinedStringRating(
      a.trim().toLowerCase(),
      b.trim().toLowerCase(),
    );
  }
  var best = 0.0;
  for (final x in ta) {
    for (final y in tb) {
      final sim = combinedStringRating(x, y);
      if (sim > best) best = sim;
    }
  }
  return best;
}
