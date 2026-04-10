import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

import '../navigation/app_routes.dart';

/// Нижняя навигация + тело веток [StatefulShellRoute.indexedStack].
///
/// Визуально как в макете: точка над активной вкладкой, центральная «парящая» кнопка +.
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  /// Ветка shell → индекс пункта нижней панели (центр = 2 зарезервирован под +).
  static int branchToNavBarIndex(int branchIndex) {
    switch (branchIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = branchToNavBarIndex(navigationShell.currentIndex);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _NavItem(
                          navIndex: 0,
                          selectedIndex: selected,
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          label: tr('home.nav.home'),
                          onTap: () => _onSideTap(context, 0),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          navIndex: 1,
                          selectedIndex: selected,
                          icon: Icons.receipt_long_outlined,
                          selectedIcon: Icons.receipt_long_rounded,
                          label: tr('home.nav.operations'),
                          onTap: () => _onSideTap(context, 1),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      Expanded(
                        child: _NavItem(
                          navIndex: 3,
                          selectedIndex: selected,
                          icon: Icons.work_outline_rounded,
                          selectedIcon: Icons.work_rounded,
                          label: tr('home.nav.budget'),
                          onTap: () => _onSideTap(context, 3),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          navIndex: 4,
                          selectedIndex: selected,
                          icon: Icons.bar_chart_outlined,
                          selectedIcon: Icons.bar_chart_rounded,
                          label: tr('home.nav.analytics'),
                          onTap: () => _onSideTap(context, 4),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 22,
                  child: _CenterAddFab(colorScheme: cs),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSideTap(BuildContext context, int navIndex) {
    HapticUtils.selection();
    // Явный go() по полному пути — надёжнее goBranch для веток shell (аналитика и др.).
    switch (navIndex) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.expenses);
        break;
      case 3:
        context.go(AppRoutes.budgets);
        break;
      case 4:
        context.go(AppRoutes.analytics);
        break;
      default:
        context.go(AppRoutes.home);
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.navIndex,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final int navIndex;
  final int selectedIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final selected = selectedIndex == navIndex;
    final iconColor = selected ? cs.primary : cs.onSurfaceVariant;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      fontSize: 11,
      letterSpacing: 0.1,
      color: selected ? cs.primary : cs.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 6,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: selected ? 5 : 0,
                  height: selected ? 5 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              selected ? selectedIcon : icon,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Круглая кнопка «+» с градиентом primary и мягкой тенью.
class _CenterAddFab extends StatelessWidget {
  const _CenterAddFab({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            Color.lerp(cs.primary, cs.tertiary, 0.4)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticUtils.selection();
            context.push(AppRoutes.expensesNew);
          },
          child: const Icon(
            Icons.add_rounded,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
