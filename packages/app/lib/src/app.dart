import 'package:easy_localization/easy_localization.dart';
import 'package:features_analytics/features_analytics.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:features_debts/features_debts.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:features_export/features_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'home/home_page.dart';
import 'onboarding/onboarding_page.dart';
import 'onboarding/onboarding_providers.dart';
import 'presentation/app_lifecycle_observer.dart';
import 'core/theme/app_theme.dart';
import 'settings/color_scheme_providers.dart';
import 'settings/settings_providers.dart';
import 'settings/settings_page.dart';

/// Красивая анимация перехода между страницами
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

final _routerProvider = Provider<GoRouter>((ref) {
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: onboardingCompleted ? '/' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const HomePage(),
        ),
      ),
      ...expensesRoutes,
      ...analyticsRoutes,
      ...debtsRoutes,
      GoRoute(
        path: '/export',
        name: 'export',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const ExportPage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: '/import',
        name: 'import',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const ImportPage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: '/backup',
        name: 'backup',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const BackupPage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const SettingsPage(),
          slideFromRight: true,
        ),
      ),
      // Бюджеты
      GoRoute(
        path: '/budgets',
        name: 'budgets',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const BudgetsListPage(),
          slideFromRight: true,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'budget_new',
            pageBuilder: (context, state) => _buildPageTransition(
              key: state.pageKey,
              child: const BudgetFormPage(),
              slideFromRight: true,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'budget_edit',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _buildPageTransition(
                key: state.pageKey,
                child: BudgetFormPage(budgetId: id),
                slideFromRight: true,
              );
            },
          ),
        ],
      ),
    ],
  );
});

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final appThemeType = ref.watch(appThemeTypeProvider);

    return AppLifecycleObserver(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: tr('app_title'),
        routerConfig: router,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: locale ?? context.locale,
        themeMode: themeMode,
        theme: AppTheme.light(appThemeType),
        darkTheme: AppTheme.dark(appThemeType),
      ),
    );
  }
}
