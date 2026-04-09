import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  final foodId = 'cat-food';
  final transportId = 'cat-transport';

  Category cat(String id, CategoryKind kind) => Category(
        id: id,
        name: id,
        colorValue: 0,
        kind: kind,
      );

  Expense exp({
    required String note,
    required String categoryId,
  }) =>
      Expense(
        id: 'e-$note',
        amount: Money(amountInCents: 100, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime.utc(2025, 1, 1),
        categoryId: categoryId,
        note: note,
      );

  test('fuzzy rule matches typo', () {
    final rule = CategoryRule(
      keyword: 'magnum',
      categoryId: foodId,
      priority: 5,
    );
    final pipeline = TransactionCategorizationPipeline(
      rules: [rule],
      history: const [],
      categories: [cat(foodId, CategoryKind.expense)],
      type: ExpenseType.expense,
    );
    final r = pipeline.categorize('Magnun доставка');
    expect(r.source, CategorizationSource.fuzzyRule);
    expect(r.categoryId, foodId);
    expect(r.confidence, greaterThan(0.5));
  });

  test('history fuzzy picks dominant category', () {
    final pipeline = TransactionCategorizationPipeline(
      rules: const [],
      history: [
        exp(note: 'Magnum на Абая', categoryId: foodId),
        exp(note: 'Magnum 24/7', categoryId: foodId),
        exp(note: 'Яндекс Такси', categoryId: transportId),
      ],
      categories: [
        cat(foodId, CategoryKind.expense),
        cat(transportId, CategoryKind.expense),
      ],
      type: ExpenseType.expense,
    );
    final r = pipeline.categorize('Magnum Алматы');
    expect(r.source, CategorizationSource.historyFuzzy);
    expect(r.categoryId, foodId);
  });

  test('exact rule wins over fuzzy', () {
    final exact = CategoryRule(
      keyword: 'яндекс',
      categoryId: transportId,
      priority: 1,
    );
    final pipeline = TransactionCategorizationPipeline(
      rules: [exact],
      history: const [],
      categories: [cat(transportId, CategoryKind.expense)],
      type: ExpenseType.expense,
    );
    final r = pipeline.categorize('Яндекс Такси');
    expect(r.source, CategorizationSource.rule);
    expect(r.categoryId, transportId);
  });
}
