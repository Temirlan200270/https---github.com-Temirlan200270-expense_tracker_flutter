import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('levenshteinDistance', () {
    test('identical', () {
      expect(levenshteinDistance('magnum', 'magnum'), 0);
    });

    test('one typo', () {
      expect(levenshteinDistance('magnum', 'magnun'), 1);
    });

    test('empty', () {
      expect(levenshteinDistance('', 'abc'), 3);
    });
  });

  group('bestTokenToKeywordSimilarity', () {
    test('typo in token', () {
      final s = bestTokenToKeywordSimilarity('Magnun shop', 'magnum');
      expect(s, greaterThanOrEqualTo(kFuzzyRuleMinSimilarity));
    });

    test('variant with extra words', () {
      final s = bestTokenToKeywordSimilarity('Magnum 24/7 Almaty', 'magnum');
      expect(s, 1.0);
    });
  });

  group('sanitizeTitleForMatch', () {
    test('removes noise tokens', () {
      final s = sanitizeTitleForMatch('Magnum * MCC KZT Almaty №12345');
      expect(s.toLowerCase(), contains('magnum'));
      expect(s.toUpperCase(), isNot(contains('KZT')));
      expect(s.toLowerCase(), isNot(contains('almaty')));
    });

    test('Kaspi statement stop words leave merchant', () {
      final s = sanitizeTitleForMatch(
        'PURCHASE KASPI QR RETAIL PAYMENT Magnum POS KZT',
      );
      expect(s.toLowerCase(), 'magnum');
    });
  });

  group('combinedStringRating', () {
    test('Dice helps on reorder or overlap', () {
      final r = combinedStringRating('magnum', 'magnmu');
      expect(r, greaterThanOrEqualTo(kMinCategorizationRating));
    });
  });
}
