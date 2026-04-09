import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/categorization_service.dart';
import 'category_rules_providers.dart';
import 'expenses_providers.dart';

/// Сервис категоризации с внедрёнными репозиториями из приложения.
final categorizationServiceProvider = Provider<CategorizationService>((ref) {
  return CategorizationService(
    categoryRulesRepository: ref.watch(categoryRulesRepositoryProvider),
    expensesRepository: ref.watch(expensesRepositoryProvider),
    categoriesRepository: ref.watch(categoriesRepositoryProvider),
  );
});
