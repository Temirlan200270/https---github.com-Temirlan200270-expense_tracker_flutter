import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import '../../services/backup_service.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:features_debts/features_debts.dart';
import 'package:data_core/data_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_components/ui_components.dart';

import '../layout/import_layout_spacing.dart';
import '../widgets/import_surface_card.dart';

void _backupSnackError(BuildContext context, String message) {
  if (!context.mounted) return;
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.errorContainer,
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onErrorContainer,
            ),
      ),
    ),
  );
}

void _backupSnackSuccess(BuildContext context, String message) {
  if (!context.mounted) return;
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.primaryContainer,
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer,
            ),
      ),
    ),
  );
}

void _backupSnackNeutral(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(message),
    ),
  );
}

/// Провайдер для BackupService
final backupServiceProvider = Provider<BackupService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final expensesRepo = ref.watch(expensesRepositoryProvider);
  final categoriesRepo = ref.watch(categoriesRepositoryProvider);
  
  // Опциональные репозитории (могут быть не доступны в старых версиях)
  BudgetsRepository? budgetsRepo;
  DebtsRepository? debtsRepo;
  CategoryRulesRepository? categoryRulesRepo;
  RecurringExpensesRepository? recurringExpensesRepo;
  
  try {
    budgetsRepo = ref.watch(budgetsRepositoryProvider);
  } catch (_) {}
  
  try {
    debtsRepo = ref.watch(debtsRepositoryProvider);
  } catch (_) {}
  
  try {
    categoryRulesRepo = ref.watch(categoryRulesRepositoryProvider);
  } catch (_) {}
  
  try {
    recurringExpensesRepo = ref.watch(recurringExpensesRepositoryProvider);
  } catch (_) {}
  
  return BackupService(
    database: database,
    expensesRepo: expensesRepo,
    categoriesRepo: categoriesRepo,
    budgetsRepo: budgetsRepo,
    debtsRepo: debtsRepo,
    categoryRulesRepo: categoryRulesRepo,
    recurringExpensesRepo: recurringExpensesRepo,
  );
});

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  @override
  Widget build(BuildContext context) {
    final backupService = ref.watch(backupServiceProvider);
    final cs = Theme.of(context).colorScheme;

    return PrimaryScaffold(
      title: tr('backup.title'),
      child: ListView(
          padding: ImportLayoutSpacing.screenPadding,
          children: [
          ImportSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.all(ImportLayoutSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup_rounded, size: 24, color: cs.primary),
                      const SizedBox(width: ImportLayoutSpacing.s12),
                      Expanded(
                        child: Text(
                          tr('backup.create'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ImportLayoutSpacing.s16),
                  Text(
                    tr('backup.create_description'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  SizedBox(height: ImportLayoutSpacing.s16),
                  FilledButton.icon(
                    onPressed: () => _createBackup(context, backupService),
                    icon: const Icon(Icons.save_rounded),
                    label: Text(tr('backup.create_now')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ImportLayoutSpacing.s16),

          ImportSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.all(ImportLayoutSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restore_rounded, size: 24, color: cs.secondary),
                      const SizedBox(width: ImportLayoutSpacing.s12),
                      Expanded(
                        child: Text(
                          tr('backup.restore'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ImportLayoutSpacing.s16),
                  Text(
                    tr('backup.restore_description'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  SizedBox(height: ImportLayoutSpacing.s16),
                  OutlinedButton.icon(
                    onPressed: () => _restoreBackup(context, backupService),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(tr('backup.restore_from_file')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ImportLayoutSpacing.s16),

          Text(
            tr('backup.existing'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: ImportLayoutSpacing.s12),
          FutureBuilder<List<File>>(
            future: backupService.listBackups(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                final ecs = Theme.of(context).colorScheme;
                return ImportSurfaceCard(
                  backgroundColor: ecs.errorContainer,
                  borderColor: ecs.error.withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.all(ImportLayoutSpacing.s16),
                    child: Text(
                      tr('backup.error', args: [snapshot.error.toString()]),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ecs.onErrorContainer,
                          ),
                    ),
                  ),
                );
              }

              final backups = snapshot.data ?? [];

              if (backups.isEmpty) {
                final ecs = Theme.of(context).colorScheme;
                return ImportSurfaceCard(
                  child: Padding(
                    padding: const EdgeInsets.all(ImportLayoutSpacing.s24),
                    child: Center(
                      child: Text(
                        tr('backup.no_backups'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ecs.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: backups.map((backup) {
                  return _BackupItem(
                    backup: backup,
                    backupService: backupService,
                    onRestore: () =>
                        _restoreFromFile(context, backupService, backup),
                  );
                }).toList(),
              );
            },
          ),
        ],
        ),
    );
  }

  Future<void> _createBackup(
      BuildContext context, BackupService service) async {
    try {
      // Сохраняем context перед async операциями
      final navigatorContext = context;
      // Показываем индикатор загрузки
      if (!mounted) return;
      showDialog(
        context: navigatorContext,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final backupFile = await service.createBackup();

      if (!mounted) return;
      Navigator.pop(navigatorContext); // Закрываем индикатор

      // Показываем диалог с результатом
      final share = await showDialog<bool>(
        context: navigatorContext,
        builder: (context) => AlertDialog(
          title: Text(tr('backup.created')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('backup.created_message')),
              const SizedBox(height: 8),
              Text(
                backupFile.path,
                style: Theme.of(navigatorContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('backup.share')),
            ),
          ],
        ),
      );

      if (share == true && mounted) {
        await Share.shareXFiles(
          [XFile(backupFile.path)],
          text: tr('backup.share_message'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final navigatorContext = context;
      Navigator.pop(navigatorContext); // Закрываем индикатор если открыт
      _backupSnackError(
        navigatorContext,
        tr('backup.error', args: [e.toString()]),
      );
    }
  }

  Future<void> _restoreBackup(
      BuildContext context, BackupService service) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      await _restoreFromFile(context, service, file);
    } catch (e) {
      if (!mounted) return;
      final navigatorContext = context;
      _backupSnackError(
        navigatorContext,
        tr('backup.error', args: [e.toString()]),
      );
    }
  }

  Future<void> _restoreFromFile(
    BuildContext context,
    BackupService service,
    File file,
  ) async {
    // Сохраняем context перед async операциями
    final navigatorContext = context;
    // Показываем предупреждение
    final confirmed = await showDialog<bool>(
      context: navigatorContext,
      builder: (context) => AlertDialog(
        title: Text(tr('backup.restore_confirm_title')),
        content: Text(tr('backup.restore_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(tr('backup.restore_confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Показываем индикатор загрузки
      if (!mounted) return;
      showDialog(
        context: navigatorContext,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await service.restoreBackup(file);

      if (!mounted) return;
      Navigator.pop(navigatorContext); // Закрываем индикатор

      if (result.success) {
        final parts = <String>[];
        if (result.expensesCount > 0) {
          parts.add('${result.expensesCount} ${tr('backup.expenses')}');
        }
        if (result.categoriesCount > 0) {
          parts.add('${result.categoriesCount} ${tr('backup.categories')}');
        }
        if (result.budgetsCount > 0) {
          parts.add('${result.budgetsCount} ${tr('backup.budgets')}');
        }
        if (result.debtsCount > 0) {
          parts.add('${result.debtsCount} ${tr('backup.debts')}');
        }
        if (result.categoryRulesCount > 0) {
          parts.add('${result.categoryRulesCount} ${tr('backup.category_rules')}');
        }
        if (result.recurringExpensesCount > 0) {
          parts.add('${result.recurringExpensesCount} ${tr('backup.recurring_expenses')}');
        }
        
        _backupSnackSuccess(
          navigatorContext,
          parts.isEmpty
              ? tr('backup.restored_empty')
              : '${tr('backup.restored_prefix')}: ${parts.join(', ')}',
        );
        // Обновляем список бэкапов
        setState(() {});
      } else {
        _backupSnackError(
          navigatorContext,
          tr('backup.error', args: [result.error ?? 'Unknown error']),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(navigatorContext); // Закрываем индикатор если открыт
      _backupSnackError(
        navigatorContext,
        tr('backup.error', args: [e.toString()]),
      );
    }
  }
}

class _BackupItem extends StatelessWidget {
  const _BackupItem({
    required this.backup,
    required this.backupService,
    required this.onRestore,
  });

  final File backup;
  final BackupService backupService;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<BackupInfo?>(
      future: backupService.getBackupInfo(backup),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final dateFormat = DateFormat.yMMMMd(context.locale.toLanguageTag());
        final timeFormat = DateFormat.Hm(context.locale.toLanguageTag());

        final titleText = info?.createdAt != null
            ? '${dateFormat.format(info!.createdAt!)} ${timeFormat.format(info.createdAt!)}'
            : backup.path.split('/').last;
        final metaLine = info != null
            ? [
                if (info.expensesCount > 0) '${info.expensesCount} ${tr('backup.expenses')}',
                if (info.categoriesCount > 0) '${info.categoriesCount} ${tr('backup.categories')}',
                if (info.budgetsCount > 0) '${info.budgetsCount} ${tr('backup.budgets')}',
                if (info.debtsCount > 0) '${info.debtsCount} ${tr('backup.debts')}',
                if (info.categoryRulesCount > 0)
                  '${info.categoryRulesCount} ${tr('backup.category_rules')}',
                if (info.recurringExpensesCount > 0)
                  '${info.recurringExpensesCount} ${tr('backup.recurring_expenses')}',
                info.formattedSize,
              ].where((s) => s.isNotEmpty).join(', ')
            : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: ImportLayoutSpacing.s8),
          child: ImportSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ImportLayoutSpacing.s12,
                vertical: ImportLayoutSpacing.s8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.backup_rounded, size: 28, color: cs.primary),
                  SizedBox(width: ImportLayoutSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (metaLine.isNotEmpty) ...[
                          SizedBox(height: ImportLayoutSpacing.s4),
                          Text(
                            metaLine,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore_rounded),
                        onPressed: onRestore,
                        tooltip: tr('backup.restore'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => _shareBackup(context),
                        tooltip: tr('backup.share'),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                        onPressed: () => _deleteBackup(context),
                        tooltip: tr('delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareBackup(BuildContext context) async {
    try {
      await Share.shareXFiles(
        [XFile(backup.path)],
        text: tr('backup.share_message'),
      );
    } catch (e) {
      _backupSnackError(context, tr('backup.error', args: [e.toString()]));
    }
  }

  Future<void> _deleteBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('backup.delete_title')),
        content: Text(tr('backup.delete_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await backupService.deleteBackup(backup);
      if (context.mounted) {
        _backupSnackNeutral(
          context,
          deleted ? tr('backup.deleted') : tr('backup.delete_error'),
        );
      }
    }
  }
}
