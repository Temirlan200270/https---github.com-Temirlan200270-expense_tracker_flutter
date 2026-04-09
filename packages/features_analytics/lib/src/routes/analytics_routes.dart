import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/analytics_page.dart';

/// Красивая анимация перехода
CustomTransitionPage<T> _buildPageTransition<T>({
  required Widget child,
  required LocalKey key,
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

List<GoRoute> analyticsRoutes = [
  GoRoute(
    path: '/analytics',
    name: 'analytics',
    pageBuilder: (context, state) => _buildPageTransition(
      key: state.pageKey,
      child: const AnalyticsPage(),
    ),
  ),
];
