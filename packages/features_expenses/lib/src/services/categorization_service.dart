import 'package:data_core/data_core.dart';
import 'package:shared_models/shared_models.dart';

/// Сервис подсказки категории по названию/заметке (Matching Engine + история).
///
/// Использует [TransactionCategorizationPipeline]: правила → fuzzy → история.
/// Удобен для экранов ввода, импорта и тестов с реальными репозиториями.
class CategorizationService {
  CategorizationService({
    required CategoryRulesRepository categoryRulesRepository,
    required ExpensesRepository expensesRepository,
    required CategoriesRepository categoriesRepository,
  })  : _rules = categoryRulesRepository,
        _expenses = expensesRepository,
        _categories = categoriesRepository;

  final CategoryRulesRepository _rules;
  final ExpensesRepository _expenses;
  final CategoriesRepository _categories;

  /// Асинхронная подсказка: загружает правила, все траты и категории.
  Future<CategorizationResult> suggestCategory({
    required String title,
    required ExpenseType type,
    ExpenseFilter expenseFilter = const ExpenseFilter(),
  }) async {
    final rules = await _rules.fetchRules();
    final history = await _expenses.fetchExpenses(filter: expenseFilter);
    final categories = await _categories.fetchAll();
    final pipeline = TransactionCategorizationPipeline(
      rules: rules,
      history: history,
      categories: categories,
      type: type,
    );
    return pipeline.categorize(title);
  }

  /// Синхронный расчёт, если данные уже в памяти (стримы Riverpod).
  CategorizationResult suggestCategorySync({
    required String title,
    required ExpenseType type,
    required List<CategoryRule> rules,
    required List<Expense> history,
    required List<Category> categories,
  }) {
    final pipeline = TransactionCategorizationPipeline(
      rules: rules,
      history: history,
      categories: categories,
      type: type,
    );
    return pipeline.categorize(title);
  }

  /// Массовая категоризация импорта: один запрос правил/истории/категорий, затем пайплайн по каждой строке.
  Future<List<PendingImportExpense>> enrichImportedExpenses(
    List<Expense> parsed,
  ) async {
    if (parsed.isEmpty) return [];

    final rules = await _rules.fetchRules();
    final history = await _expenses.fetchExpenses();
    final categories = await _categories.fetchAll();

    return parsed.map((e) {
      final pipeline = TransactionCategorizationPipeline(
        rules: rules,
        history: history,
        categories: categories,
        type: e.type,
      );
      final title = e.note ?? '';
      final r = pipeline.categorize(title);
      final row = PendingImportExpense(
        parsed: e,
        predictedCategoryId: r.categoryId,
        confidence: r.confidence,
        predictionSource: r.source,
      );
      return row.copyWith(isIncluded: row.defaultIsIncludedForReview);
    }).toList();
  }
}
