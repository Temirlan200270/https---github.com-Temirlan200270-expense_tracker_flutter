import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/import_service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('import.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr('import.select_file'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _ImportOption(
            icon: Icons.table_chart,
            title: tr('import.csv'),
            subtitle: tr('import.csv_description'),
            onTap: () => _importCsv(context),
            enabled: !_isImporting,
          ),
          const SizedBox(height: 12),
          _ImportOption(
            icon: Icons.code,
            title: tr('import.json'),
            subtitle: tr('import.json_description'),
            onTap: () => _importJson(context),
            enabled: !_isImporting,
          ),
          const SizedBox(height: 12),
          _ImportOption(
            icon: Icons.picture_as_pdf,
            title: tr('import.pdf'),
            subtitle: tr('import.pdf_description'),
            onTap: () => _importPdf(context),
            enabled: !_isImporting,
          ),
          if (_isImporting) ...[
            const SizedBox(height: 24),
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
          await _saveExpenses(expenses);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  tr('import.success').replaceAll('{0}', expenses.length.toString()),
                ),
              ),
            );
            Navigator.of(context).pop();
          }
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
          await _saveExpenses(expenses);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  tr('import.success').replaceAll('{0}', expenses.length.toString()),
                ),
              ),
            );
            Navigator.of(context).pop();
          }
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
        print('📋 Импорт PDF: API ключ = ${geminiApiKey != null && geminiApiKey.isNotEmpty ? '${geminiApiKey.substring(0, 4)}...' : 'НЕ УСТАНОВЛЕН'}, модель = $geminiModel');
        final expenses = await _importService.importFromPdf(file, geminiApiKey: geminiApiKey, geminiModel: geminiModel, ref: ref);
        
        // Отладочная информация
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
          await _saveExpenses(expenses);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  tr('import.success').replaceAll('{0}', expenses.length.toString()),
                ),
              ),
            );
            Navigator.of(context).pop();
          }
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

  Future<void> _saveExpenses(List<Expense> expenses) async {
    if (expenses.isEmpty) {
      return;
    }
    
    final repo = ref.read(expensesRepositoryProvider);
    int savedCount = 0;
    int skippedCount = 0;
    
    for (final expense in expenses) {
      try {
        await repo.upsertExpense(expense);
        savedCount++;
      } catch (e) {
        // Логируем ошибки сохранения
        print('Ошибка сохранения записи: $e');
        skippedCount++;
      }
    }
    
    print('💾 Сохранено транзакций: $savedCount из ${expenses.length}');
    if (skippedCount > 0) {
      print('⚠️ Пропущено транзакций: $skippedCount');
    }
  }
}

class _ImportOption extends StatelessWidget {
  const _ImportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
        enabled: enabled,
      ),
    );
  }
}

