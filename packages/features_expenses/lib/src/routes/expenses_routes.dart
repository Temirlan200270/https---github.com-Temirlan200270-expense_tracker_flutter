import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../presentation/pages/expenses_list_page.dart';
import '../presentation/pages/new_expense_page.dart';
import '../presentation/pages/categories_page.dart';
import '../presentation/pages/category_rules_page.dart';
import '../presentation/pages/recurring_expenses_page.dart';
import '../presentation/pages/new_recurring_expense_page.dart';

/// Красивая анимация перехода
CustomTransitionPage<T> _buildPageTransition<T>({
  required Widget child,
  required LocalKey key,
  bool slideFromRight = false,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      if (slideFromRight) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      }

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.03),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

List<GoRoute> expensesRoutes = [
  GoRoute(
    path: '/categories',
    name: 'categories',
    pageBuilder: (context, state) => _buildPageTransition(
      key: state.pageKey,
      child: const CategoriesPage(),
      slideFromRight: true,
    ),
  ),
  GoRoute(
    path: '/rules',
    name: 'categoryRules',
    pageBuilder: (context, state) => _buildPageTransition(
      key: state.pageKey,
      child: const CategoryRulesPage(),
      slideFromRight: true,
    ),
  ),
  GoRoute(
    path: '/expenses',
    name: 'expensesList',
    pageBuilder: (context, state) => _buildPageTransition(
      key: state.pageKey,
      child: const ExpensesListPage(),
    ),
    routes: [
      GoRoute(
        path: 'new',
        name: 'newExpense',
        pageBuilder: (context, state) {
          ExpenseType? initialType;
          Expense? expense;
          
          // Пробуем получить expense для редактирования
          if (state.extra is Expense) {
            expense = state.extra as Expense;
          } else if (state.extra is Map) {
            final extra = state.extra as Map;
            expense = extra['expense'] as Expense?;
            
            // Или тип из extra параметров
            final typeParam = extra['type'] as String?;
            if (typeParam == 'expense') {
              initialType = ExpenseType.expense;
            } else if (typeParam == 'income') {
              initialType = ExpenseType.income;
            }
          }
          
          // Если не нашли в extra, пробуем query параметры
          if (initialType == null && expense == null) {
            final fullPath = state.fullPath;
            if (fullPath != null && fullPath.contains('?')) {
              try {
                final uri = Uri.parse(fullPath);
                final typeParam = uri.queryParameters['type'];
                if (typeParam == 'expense') {
                  initialType = ExpenseType.expense;
                } else if (typeParam == 'income') {
                  initialType = ExpenseType.income;
                }
              } catch (e) {
                // Если не удалось распарсить, используем значение по умолчанию
              }
            }
          }
          
          return _buildPageTransition(
            key: state.pageKey,
            child: NewExpensePage(
              initialType: initialType,
              expense: expense,
            ),
            slideFromRight: true,
          );
        },
      ),
    ],
  ),
  GoRoute(
    path: '/recurring',
    name: 'recurringExpenses',
    pageBuilder: (context, state) => _buildPageTransition(
      key: state.pageKey,
      child: const RecurringExpensesPage(),
    ),
    routes: [
      GoRoute(
        path: 'new',
        name: 'newRecurringExpense',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const NewRecurringExpensePage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: 'edit',
        name: 'editRecurringExpense',
        pageBuilder: (context, state) {
          RecurringExpense? recurring;
          if (state.extra is RecurringExpense) {
            recurring = state.extra as RecurringExpense;
          } else if (state.extra is Map) {
            recurring = (state.extra as Map)['recurring'] as RecurringExpense?;
          }
          return _buildPageTransition(
            key: state.pageKey,
            child: NewRecurringExpensePage(recurringExpense: recurring),
            slideFromRight: true,
          );
        },
      ),
    ],
  ),
];
