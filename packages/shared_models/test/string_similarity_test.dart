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
}
