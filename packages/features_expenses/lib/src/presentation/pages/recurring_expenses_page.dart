import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/expenses_providers.dart';
import '../../services/recurring_expenses_service.dart';

/// Провайдер для сервиса повторяющихся транзакций
final recurringExpensesServiceProvider =
    Provider<RecurringExpensesService>((ref) {
  final recurringRepo = ref.watch(recurringExpensesRepositoryProvider);
  final expensesRepo = ref.watch(expensesRepositoryProvider);
  return RecurringExpensesService(
    recurringRepo: recurringRepo,
    expensesRepo: expensesRepo,
  );
});

class RecurringExpensesPage extends ConsumerWidget {
  const RecurringExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringExpensesStreamProvider);
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('recurring.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticUtils.selection();
              context.push('/recurring/new');
            },
            tooltip: tr('recurring.create'),
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (recurringList) {
          if (recurringList.isEmpty) {
            return EmptyState(
              icon: Icons.repeat,
              title: tr('recurring.empty'),
              message: tr('recurring.empty_hint'),
              action: FilledButton.icon(
                onPressed: () {
                  HapticUtils.selection();
                  context.push('/recurring/new');
                },
                icon: const Icon(Icons.add),
                label: Text(tr('recurring.create')),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(recurringExpensesStreamProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recurringList.length,
              itemBuilder: (context, index) {
                final recurring = recurringList[index];
                return _RecurringExpenseCard(
                  recurring: recurring,
                  formatter: formatter,
                  onTap: () {
                    HapticUtils.selection();
                    context.push('/recurring/edit',
                        extra: {'recurring': recurring});
                  },
                  onToggleActive: () => _toggleActive(context, ref, recurring),
                  onGenerate: () => _generateExpense(context, ref, recurring),
                  onDelete: () => _deleteRecurring(context, ref, recurring),
                );
              },
            ),
          );
        },
        loading: () => const SkeletonList(itemCount: 5),
        error: (error, _) => Center(
          child: Text(tr('recurring.error', args: [error.toString()])),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticUtils.mediumImpact();
          context.push('/recurring/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense recurring,
  ) async {
    HapticUtils.selection();
    final repo = ref.read(recurringExpensesRepositoryProvider);
    await repo.upsert(recurring.copyWith(isActive: !recurring.isActive));
  }

  Future<void> _generateExpense(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense recurring,
  ) async {
    HapticUtils.mediumImpact();
    final service = ref.read(recurringExpensesServiceProvider);

    try {
      await service.generateExpenseManually(recurring);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('recurring.generated'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('recurring.error', args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecurring(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense recurring,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('recurring.delete_title')),
        content: Text(tr('recurring.delete_message')),
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
      HapticUtils.mediumImpact();
      final repo = ref.read(recurringExpensesRepositoryProvider);
      await repo.softDelete(recurring.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('recurring.deleted'))),
        );
      }
    }
  }
}

class _RecurringExpenseCard extends StatelessWidget {
  const _RecurringExpenseCard({
    required this.recurring,
    required this.formatter,
    required this.onTap,
    required this.onToggleActive,
    required this.onGenerate,
    required this.onDelete,
  });

  final RecurringExpense recurring;
  final NumberFormat formatter;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onGenerate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = recurring.type.isIncome ? Colors.green : Colors.red;
    final dateFormat = DateFormat.yMMMMd(context.locale.toLanguageTag());

    return EnhancedExpenseCard(
      gradient: recurring.type.isIncome ? IncomeGradient() : ExpenseGradient(),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recurring.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(recurring.amount.amount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: recurring.isActive,
                  onChanged: (_) => onToggleActive(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  context.locale.languageCode == 'ru'
                      ? recurring.recurrenceType.displayName
                      : recurring.recurrenceType.displayNameEn,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(recurring.startDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (recurring.nextOccurrence != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${tr('recurring.next_occurrence')}: ${dateFormat.format(recurring.nextOccurrence!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(tr('recurring.generate_now')),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
