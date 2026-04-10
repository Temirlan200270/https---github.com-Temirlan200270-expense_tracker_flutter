import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../services/import_service.dart';
import '../import_review/import_review_controller.dart';
import '../layout/import_layout_spacing.dart';
import '../widgets/import_surface_card.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final _importService = ImportService();
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PrimaryScaffold(
      title: tr('import.title'),
      child: ListView(
          padding: ImportLayoutSpacing.screenPadding,
          children: [
            Text(
              tr('import.select_file'),
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
            _ImportOption(
              icon: Icons.table_chart_rounded,
              iconColor: cs.primary,
              title: tr('import.csv'),
              subtitle: tr('import.csv_description'),
              onTap: () => _importCsv(context),
              enabled: !_isImporting,
              animationIndex: 0,
            ),
            SizedBox(height: ImportLayoutSpacing.s12),
            _ImportOption(
              icon: Icons.code_rounded,
              iconColor: cs.secondary,
              title: tr('import.json'),
              subtitle: tr('import.json_description'),
              onTap: () => _importJson(context),
              enabled: !_isImporting,
              animationIndex: 1,
            ),
            SizedBox(height: ImportLayoutSpacing.s12),
            _ImportOption(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: cs.tertiary,
              title: tr('import.pdf'),
              subtitle: tr('import.pdf_description'),
              onTap: () => _importPdf(context),
              enabled: !_isImporting,
              animationIndex: 2,
            ),
            if (_isImporting) ...[
              SizedBox(height: ImportLayoutSpacing.s24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final expenses = await _importService.importFromCsv(file);
        final errors = _importService.validateImportData(expenses);

        if (errors.isNotEmpty) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(tr('import.validation_errors')),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors.map((e) => Text(e)).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('import.close')),
                  ),
                ],
              ),
            );
          }
        } else {
          await _openImportReview(context, expenses);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('import.error', args: [e.toString()]))),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importJson(BuildContext context) async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path;
        if (filePath == null) return;
        final file = File(filePath);
        final expenses = await _importService.importFromJson(file);
        final errors = _importService.validateImportData(expenses);

        if (errors.isNotEmpty) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(tr('import.validation_errors')),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors.map((e) => Text(e)).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('import.close')),
                  ),
                ],
              ),
            );
          }
        } else {
          await _openImportReview(context, expenses);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('import.error', args: [e.toString()]))),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importPdf(BuildContext context) async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path;
        if (filePath == null) return;
        final file = File(filePath);
        // Получаем API ключ и модель из провайдеров
        final geminiApiKey = ref.read(geminiApiKeyProvider);
        final geminiModel = ref.read(geminiModelProvider);
        final expenses = await _importService.importFromPdf(
          file,
          geminiApiKey: geminiApiKey,
          geminiModel: geminiModel,
          ref: ref,
        );

        if (expenses.isEmpty) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(tr('import.pdf_error')),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('import.pdf_error_details')),
                      const SizedBox(height: 16),
                      Text(tr('import.pdf_alternatives'), style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(tr('import.pdf_alternative1')),
                      Text(tr('import.pdf_alternative2')),
                      Text(tr('import.pdf_alternative3')),
                      Text(tr('import.pdf_alternative4')),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('import.close')),
                  ),
                ],
              ),
            );
          }
          return;
        }
        
        final errors = _importService.validateImportData(expenses);

        if (errors.isNotEmpty) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(tr('import.validation_errors')),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors.map((e) => Text(e)).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('import.close')),
                  ),
                ],
              ),
            );
          }
        } else {
          await _openImportReview(context, expenses);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('import.error', args: [e.toString()]))),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  /// Обогащение и экран подтверждения перед записью в БД.
  Future<void> _openImportReview(
    BuildContext context,
    List<Expense> expenses,
  ) async {
    if (expenses.isEmpty) return;

    final service = ref.read(categorizationServiceProvider);
    final pending = await service.enrichImportedExpenses(expenses);
    ref.read(importReviewControllerProvider.notifier).stage(pending);

    if (!context.mounted) return;
    await context.push('/import/review');
  }
}

class _ImportOption extends StatelessWidget {
  const _ImportOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.enabled,
    required this.animationIndex,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ImportSurfaceCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
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

