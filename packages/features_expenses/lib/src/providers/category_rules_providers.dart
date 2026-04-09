import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_core/data_core.dart';
import 'package:local_db/local_db.dart';
import 'package:shared_models/shared_models.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';

/// Провайдер репозитория правил категоризации
final categoryRulesRepositoryProvider = Provider<CategoryRulesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalCategoryRulesRepository(db);
});

/// Провайдер потока правил
final categoryRulesStreamProvider = StreamProvider.autoDispose<List<CategoryRule>>((ref) {
  final repo = ref.watch(categoryRulesRepositoryProvider);
  return repo.watchRules();
});

/// Провайдер правил для конкретной категории
final categoryRulesForCategoryProvider = FutureProvider.autoDispose.family<List<CategoryRule>, String>((ref, categoryId) async {
  final repo = ref.watch(categoryRulesRepositoryProvider);
  return repo.getRulesByCategory(categoryId);
});

/// Провайдер CategoryRuleMatcher для применения правил
final categoryRuleMatcherProvider = FutureProvider.autoDispose<CategoryRuleMatcher>((ref) async {
  final repo = ref.watch(categoryRulesRepositoryProvider);
  return repo.getMatcher();
});

/// Контроллер для управления правилами категоризации
class CategoryRulesController extends StateNotifier<AsyncValue<void>> {
  CategoryRulesController(this._repository) : super(const AsyncValue.data(null));

  final CategoryRulesRepository _repository;

  /// Создать новое правило
  Future<void> createRule({
    required String keyword,
    required String categoryId,
    int priority = 0,
    bool caseSensitive = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Проверяем, нет ли уже такого правила
      final existing = await _repository.findRuleByKeyword(keyword);
      if (existing != null) {
        // Обновляем существующее
        await _repository.upsertRule(
          existing.copyWith(
            categoryId: categoryId,
            priority: priority,
            caseSensitive: caseSensitive,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      } else {
        // Создаём новое
        final rule = CategoryRule(
          keyword: keyword,
          categoryId: categoryId,
          priority: priority,
          caseSensitive: caseSensitive,
        );
        await _repository.upsertRule(rule);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Обновить правило
  Future<void> updateRule(CategoryRule rule) async {
    state = const AsyncValue.loading();
    try {
      await _repository.upsertRule(
        rule.copyWith(updatedAt: DateTime.now().toUtc()),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Удалить правило
  Future<void> deleteRule(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteRule(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Быстрое создание правила из текста транзакции
  /// Извлекает ключевое слово из текста (первое слово или название магазина)
  Future<void> createRuleFromText({
    required String text,
    required String categoryId,
  }) async {
    // Извлекаем ключевое слово - берём первое значимое слово или всё
    String keyword = text.trim();
    
    // Если текст длинный, берём только первую часть (до запятой, точки с запятой и т.д.)
    if (keyword.contains(',')) {
      keyword = keyword.split(',').first.trim();
    }
    if (keyword.contains(';')) {
      keyword = keyword.split(';').first.trim();
    }
    
    // Ограничиваем длину
    if (keyword.length > 50) {
      keyword = keyword.substring(0, 50);
    }
    
    if (keyword.isNotEmpty) {
      await createRule(keyword: keyword, categoryId: categoryId);
    }
  }
}

/// Провайдер контроллера правил
final categoryRulesControllerProvider =
    StateNotifierProvider.autoDispose<CategoryRulesController, AsyncValue<void>>((ref) {
  final repo = ref.watch(categoryRulesRepositoryProvider);
  return CategoryRulesController(repo);
});

/// Функция для применения правил к тексту транзакции
/// Возвращает categoryId или null
Future<String?> applyCategoryRule(WidgetRef ref, String text) async {
  try {
    final matcher = await ref.read(categoryRuleMatcherProvider.future);
    return matcher.findCategoryId(text);
  } catch (_) {
    return null;
  }
}

