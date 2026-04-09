import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/export_service.dart';
import 'package:features_expenses/features_expenses.dart';

class ExportPage extends ConsumerWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('export.title')),
      ),
      body: expensesAsync.when(
        data: (expenses) => _ExportOptions(expenses: expenses),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(tr('export.error', args: [error.toString()])),
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
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              tr('export.no_data'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    final exportService = ExportService();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tr('export.select_format'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _ExportOption(
          icon: Icons.table_chart,
          title: tr('export.csv'),
          subtitle: tr('export.csv_description'),
          onTap: () => _exportCsv(context, exportService),
        ),
        const SizedBox(height: 12),
        _ExportOption(
          icon: Icons.code,
          title: tr('export.json'),
          subtitle: tr('export.json_description'),
          onTap: () => _exportJson(context, exportService),
        ),
        const SizedBox(height: 12),
        _ExportOption(
          icon: Icons.picture_as_pdf,
          title: tr('export.pdf'),
          subtitle: tr('export.pdf_description'),
          onTap: () => _exportPdf(context, exportService),
        ),
        const SizedBox(height: 24),
        Text(
          tr('export.count', args: [expenses.length.toString()]),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _exportCsv(BuildContext context, ExportService service) async {
    try {
      final file = await service.exportToCsv(expenses);
      await Share.shareXFiles([XFile(file.path)],
          text: tr('export.share_message'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('export.success'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('export.error', args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _exportJson(BuildContext context, ExportService service) async {
    try {
      final file = await service.exportToJson(expenses);
      await Share.shareXFiles([XFile(file.path)],
          text: tr('export.share_message'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('export.success'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('export.error', args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _exportPdf(BuildContext context, ExportService service) async {
    try {
      await service.exportToPdf(expenses);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('export.success'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('export.error', args: [e.toString()]))),
        );
      }
    }
  }
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
