import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../services/export_service.dart';
import '../layout/import_layout_spacing.dart';
import '../widgets/import_surface_card.dart';
import 'package:features_expenses/features_expenses.dart';

void _showExportSnackBar(
  BuildContext context,
  String message, {
  required bool isError,
}) {
  if (!context.mounted) return;
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? cs.errorContainer : cs.primaryContainer,
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isError ? cs.onErrorContainer : cs.onPrimaryContainer,
            ),
      ),
    ),
  );
}

class ExportPage extends ConsumerWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return PrimaryScaffold(
      title: tr('export.title'),
      child: expensesAsync.when(
        data: (expenses) => _ExportOptions(expenses: expenses),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          title: tr('error_state.title'),
          message: tr('export.error', args: [error.toString()]),
          action: PrimaryActionButton(
            onPressed: () => ref.invalidate(expensesStreamProvider),
            child: Text(tr('retry')),
          ),
        ),
      ),
    );
  }
}

class _ExportOptions extends StatelessWidget {
  const _ExportOptions({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (expenses.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_rounded,
        title: tr('export.no_data'),
      );
    }

    final exportService = ExportService();

    return ListView(
        padding: ImportLayoutSpacing.screenPadding,
        children: [
          Text(
            tr('export.select_format'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          )
              .animate()
              .fadeIn(duration: AppMotion.standard, curve: AppMotion.curve)
              .slideY(
                begin: 0.06,
                duration: AppMotion.standard,
                curve: AppMotion.curve,
              ),
          SizedBox(height: ImportLayoutSpacing.s16),
          _ExportOption(
            icon: Icons.table_chart_rounded,
            iconColor: cs.primary,
            title: tr('export.csv'),
            subtitle: tr('export.csv_description'),
            onTap: () => _exportCsv(context, exportService),
            animationIndex: 0,
          ),
          SizedBox(height: ImportLayoutSpacing.s12),
          _ExportOption(
            icon: Icons.code_rounded,
            iconColor: cs.secondary,
            title: tr('export.json'),
            subtitle: tr('export.json_description'),
            onTap: () => _exportJson(context, exportService),
            animationIndex: 1,
          ),
          SizedBox(height: ImportLayoutSpacing.s12),
          _ExportOption(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: cs.tertiary,
            title: tr('export.pdf'),
            subtitle: tr('export.pdf_description'),
            onTap: () => _exportPdf(context, exportService),
            animationIndex: 2,
          ),
          SizedBox(height: ImportLayoutSpacing.s24),
          Text(
            tr('export.count', args: [expenses.length.toString()]),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
    );
  }

  Future<void> _exportCsv(BuildContext context, ExportService service) async {
    try {
      final file = await service.exportToCsv(expenses);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: tr('export.share_message'),
      );
      _showExportSnackBar(context, tr('export.success'), isError: false);
    } catch (e) {
      _showExportSnackBar(
        context,
        tr('export.error', args: [e.toString()]),
        isError: true,
      );
    }
  }

  Future<void> _exportJson(BuildContext context, ExportService service) async {
    try {
      final file = await service.exportToJson(expenses);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: tr('export.share_message'),
      );
      _showExportSnackBar(context, tr('export.success'), isError: false);
    } catch (e) {
      _showExportSnackBar(
        context,
        tr('export.error', args: [e.toString()]),
        isError: true,
      );
    }
  }

  Future<void> _exportPdf(BuildContext context, ExportService service) async {
    try {
      await service.exportToPdf(expenses);
      _showExportSnackBar(context, tr('export.success'), isError: false);
    } catch (e) {
      _showExportSnackBar(
        context,
        tr('export.error', args: [e.toString()]),
        isError: true,
      );
    }
  }
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.animationIndex,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ImportSurfaceCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: CompactRow(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            title: title,
            subtitle: subtitle,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ImportLayoutSpacing.s20,
              vertical: ImportLayoutSpacing.s12,
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: AppMotion.standard,
          delay: AppMotion.staggerInterval * animationIndex,
          curve: AppMotion.curve,
        )
        .slideY(
          begin: 0.08,
          duration: AppMotion.standard,
          delay: AppMotion.staggerInterval * animationIndex,
          curve: AppMotion.curve,
        );
  }
}
