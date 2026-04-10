import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

import 'home_layout_shell.dart';

/// Показывает bottom sheet «Быстрые переходы» (настройки, бюджеты, экспорт и т.д.).
void showHomeMoreSheet(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      void go(String route) {
        Navigator.pop(sheetContext);
        context.push(route);
      }

      Widget sectionLabel(String key) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: HomeLayoutSpacing.s8,
            top: HomeLayoutSpacing.s8,
          ),
          child: Text(
            tr(key).toUpperCase(),
            style: Theme.of(sheetContext).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
          ),
        );
      }

      Widget divider() {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: HomeLayoutSpacing.s8),
          child: Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
        );
      }

      return SssSheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('home.more_sheet.title'),
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: HomeLayoutSpacing.s12),
            sectionLabel('home.more_sheet.section_finance'),
            HomeSheetAction(
              icon: Icons.account_balance_rounded,
              label: tr('debts.title'),
              foregroundColor: cs.primary,
              onTap: () => go(AppRoutes.debts),
            ),
            HomeSheetAction(
              icon: Icons.category_rounded,
              label: tr('categories.title'),
              foregroundColor: cs.primary,
              onTap: () => go(AppRoutes.categories),
            ),
            HomeSheetAction(
              icon: Icons.repeat_rounded,
              label: tr('recurring.title'),
              foregroundColor: cs.primary,
              onTap: () => go(AppRoutes.recurring),
            ),
            divider(),
            sectionLabel('home.more_sheet.section_data'),
            HomeSheetAction(
              icon: Icons.upload_file_rounded,
              label: tr('export.title'),
              foregroundColor: cs.primary,
              onTap: () => go(AppRoutes.export),
            ),
            HomeSheetAction(
              icon: Icons.download_rounded,
              label: tr('import.title'),
              foregroundColor: cs.primary,
              onTap: () => go(AppRoutes.import),
            ),
            divider(),
            sectionLabel('home.more_sheet.section_app'),
            HomeSheetAction(
              icon: Icons.settings_rounded,
              label: tr('settings'),
              foregroundColor: cs.primary,
              onTap: () => go(AppRoutes.settings),
            ),
          ],
        ),
      );
    },
  );
}

/// Строка действия в bottom sheet (без ListTile — ровный spacing).
class HomeSheetAction extends StatelessWidget {
  const HomeSheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = foregroundColor ?? cs.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeLayoutSpacing.s20,
            vertical: HomeLayoutSpacing.s12,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: fg),
              SizedBox(width: HomeLayoutSpacing.s16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
