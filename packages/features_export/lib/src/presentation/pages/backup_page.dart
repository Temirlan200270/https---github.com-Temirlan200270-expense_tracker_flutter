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

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('backup.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Создание бэкапа
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.backup, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        tr('backup.create'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('backup.create_description'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _createBackup(context, backupService),
                    icon: const Icon(Icons.save),
                    label: Text(tr('backup.create_now')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Восстановление из бэкапа
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restore, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        tr('backup.restore'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('backup.restore_description'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _restoreBackup(context, backupService),
                    icon: const Icon(Icons.upload_file),
                    label: Text(tr('backup.restore_from_file')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Список существующих бэкапов
          Text(
            tr('backup.existing'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<File>>(
            future: backupService.listBackups(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tr('backup.error', args: [snapshot.error.toString()]),
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                );
              }

              final backups = snapshot.data ?? [];

              if (backups.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        tr('backup.no_backups'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
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
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        SnackBar(
          content: Text(tr('backup.error', args: [e.toString()])),
          backgroundColor: Colors.red,
        ),
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
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        SnackBar(
          content: Text(tr('backup.error', args: [e.toString()])),
          backgroundColor: Colors.red,
        ),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
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
        
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text(parts.isEmpty 
              ? tr('backup.restored_empty')
              : '${tr('backup.restored_prefix')}: ${parts.join(', ')}'),
            backgroundColor: Colors.green,
          ),
        );
        // Обновляем список бэкапов
        setState(() {});
      } else {
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text(
                tr('backup.error', args: [result.error ?? 'Unknown error'])),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(navigatorContext); // Закрываем индикатор если открыт
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        SnackBar(
          content: Text(tr('backup.error', args: [e.toString()])),
          backgroundColor: Colors.red,
        ),
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
    return FutureBuilder<BackupInfo?>(
      future: backupService.getBackupInfo(backup),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final dateFormat = DateFormat.yMMMMd(context.locale.toLanguageTag());
        final timeFormat = DateFormat.Hm(context.locale.toLanguageTag());

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.backup, size: 32),
            title: Text(
              info?.createdAt != null
                  ? '${dateFormat.format(info!.createdAt!)} ${timeFormat.format(info.createdAt!)}'
                  : backup.path.split('/').last,
            ),
            subtitle: info != null
                ? Text(
                    [
                      if (info.expensesCount > 0) '${info.expensesCount} ${tr('backup.expenses')}',
                      if (info.categoriesCount > 0) '${info.categoriesCount} ${tr('backup.categories')}',
                      if (info.budgetsCount > 0) '${info.budgetsCount} ${tr('backup.budgets')}',
                      if (info.debtsCount > 0) '${info.debtsCount} ${tr('backup.debts')}',
                      if (info.categoryRulesCount > 0) '${info.categoryRulesCount} ${tr('backup.category_rules')}',
                      if (info.recurringExpensesCount > 0) '${info.recurringExpensesCount} ${tr('backup.recurring_expenses')}',
                      info.formattedSize,
                    ].where((s) => s.isNotEmpty).join(', '),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: onRestore,
                  tooltip: tr('backup.restore'),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareBackup(context),
                  tooltip: tr('backup.share'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteBackup(context),
                  tooltip: tr('delete'),
                ),
              ],
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('backup.error', args: [e.toString()]))),
        );
      }
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await backupService.deleteBackup(backup);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                deleted ? tr('backup.deleted') : tr('backup.delete_error')),
          ),
        );
      }
    }
  }
}
