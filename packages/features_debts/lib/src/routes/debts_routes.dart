import 'package:go_router/go_router.dart';

import '../presentation/pages/debts_list_page.dart';
import '../presentation/pages/debt_form_page.dart';

/// Маршруты для модуля долгов
List<RouteBase> debtsRoutes = [
  GoRoute(
    path: '/debts',
    builder: (context, state) => const DebtsListPage(),
    routes: [
      GoRoute(
        path: 'new',
        builder: (context, state) {
          return DebtFormPage();
        },
      ),
      GoRoute(
        path: ':id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DebtFormPage(debtId: id);
        },
      ),
    ],
  ),
];
