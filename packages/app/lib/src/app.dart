import 'package:easy_localization/easy_localization.dart';
import 'package:features_analytics/features_analytics.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:features_debts/features_debts.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:features_export/features_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'navigation/app_routes.dart';
import 'home/home_page.dart';
import 'shell/main_navigation_shell.dart';
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
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
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
    initialLocation:
        onboardingCompleted ? AppRoutes.home : AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const OnboardingPage(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => _buildPageTransition(
                  key: state.pageKey,
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: expensesShellBranchRoutes,
          ),
          StatefulShellBranch(
            routes: budgetsRoutes,
          ),
          StatefulShellBranch(
            routes: analyticsShellBranchRoutes,
          ),
        ],
      ),
      ...expensesRoutes,
      ...debtsRoutes,
      GoRoute(
        path: AppRoutes.export,
        name: 'export',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const ExportPage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.import,
        name: 'import',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const ImportPage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.importReview,
        name: 'importReview',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const ImportReviewPage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.backup,
        name: 'backup',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const BackupPage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const SettingsPage(),
          slideFromRight: true,
        ),
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
