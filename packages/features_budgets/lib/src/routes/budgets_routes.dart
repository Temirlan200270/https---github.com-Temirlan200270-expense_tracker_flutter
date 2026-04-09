import 'package:go_router/go_router.dart';

import '../presentation/pages/budgets_list_page.dart';
import '../presentation/pages/budget_form_page.dart';

/// Маршруты для модуля бюджетов
List<RouteBase> budgetsRoutes = [
  GoRoute(
    path: '/budgets',
    builder: (context, state) => const BudgetsListPage(),
    routes: [
      GoRoute(
        path: 'new',
        builder: (context, state) => const BudgetFormPage(),
      ),
      GoRoute(
        path: ':id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BudgetFormPage(budgetId: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return BudgetFormPage(budgetId: id);
            },
          ),
        ],
      ),
    ],
  ),
];
