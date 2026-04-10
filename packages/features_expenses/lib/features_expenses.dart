export 'src/controllers/expense_form_controller.dart';
export 'src/controllers/expenses_list_controller.dart';
export 'src/providers/expenses_providers.dart';
export 'src/providers/recurring_expenses_controller.dart';
export 'src/providers/category_rules_providers.dart';
export 'src/routes/expenses_routes.dart'
    show expensesRoutes, expensesShellBranchRoutes;
export 'src/presentation/pages/expenses_list_page.dart';
export 'src/presentation/pages/new_expense_page.dart';
export 'src/presentation/pages/categories_page.dart';
export 'src/presentation/pages/category_rules_page.dart';
export 'src/presentation/pages/recurring_expenses_page.dart';
export 'src/presentation/pages/new_recurring_expense_page.dart';
export 'src/services/recurring_expenses_service.dart';
export 'src/services/categorization_service.dart';
export 'src/providers/categorization_providers.dart';

// Экспорт провайдеров для использования в других пакетах
export 'src/providers/expenses_providers.dart' show expensesStreamProvider, categoriesStreamProvider, recurringExpensesStreamProvider;
export 'src/providers/category_rules_providers.dart' show categoryRulesRepositoryProvider, categoryRulesStreamProvider, categoryRuleMatcherProvider;

