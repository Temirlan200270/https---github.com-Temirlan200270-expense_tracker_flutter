import 'package:shared_models/shared_models.dart';

/// Абстрактный репозиторий для работы с правилами автокатегоризации
abstract class CategoryRulesRepository {
  /// Получить поток всех активных правил
  Stream<List<CategoryRule>> watchRules();

  /// Получить все активные правила (отсортированные по приоритету)
  Future<List<CategoryRule>> fetchRules();

  /// Получить правило по ID
  Future<CategoryRule?> getRule(String id);

  /// Получить правила для категории
  Future<List<CategoryRule>> getRulesByCategory(String categoryId);

  /// Найти правило по ключевому слову (точное совпадение)
  Future<CategoryRule?> findRuleByKeyword(String keyword);

  /// Создать или обновить правило
  Future<void> upsertRule(CategoryRule rule);

  /// Удалить правило
  Future<void> deleteRule(String id);

  /// Увеличить счётчик срабатываний правила
  Future<void> incrementMatchCount(String id);

  /// Получить CategoryRuleMatcher с актуальными правилами
  Future<CategoryRuleMatcher> getMatcher();
}

