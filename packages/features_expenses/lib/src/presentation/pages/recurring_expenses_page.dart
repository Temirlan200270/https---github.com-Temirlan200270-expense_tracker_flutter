import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/expenses_providers.dart';
import '../../providers/recurring_expenses_controller.dart';

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

    return PrimaryScaffold(
      title: tr('recurring.title'),
      fab: FloatingActionButton(
        onPressed: () {
          HapticUtils.mediumImpact();
          context.push('/recurring/new');
        },
        child: const Icon(Icons.add_rounded),
      ),
      child: recurringAsync.when(
        data: (_) {
          final recurringList = ref.watch(recurringExpensesDisplayListProvider);
          if (recurringList.isEmpty) {
            return EmptyState(
              icon: Icons.repeat,
              title: tr('recurring.empty'),
              message: tr('recurring.empty_hint'),
              action: PrimaryActionButton(
                onPressed: () {
                  HapticUtils.selection();
                  context.push('/recurring/new');
                },
                icon: const Icon(Icons.add_rounded),
                child: Text(tr('recurring.create')),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(recurringExpensesStreamProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: recurringList.length,
              itemBuilder: (context, index) {
                final recurring = recurringList[index];
                final rowDelay = AppMotion.staggerInterval * index;
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
                )
                    .animate()
                    .fadeIn(
                      duration: AppMotion.standard,
                      delay: rowDelay,
                      curve: AppMotion.curve,
                    )
                    .slideY(
                      begin: 0.05,
                      duration: AppMotion.standard,
                      delay: rowDelay,
                      curve: AppMotion.curve,
                    );
              },
            ),
          );
        },
        loading: () => const SkeletonList(itemCount: 5),
        error: (_, __) => ErrorState(
          title: tr('error_state.title'),
          message: tr('error_state.message'),
          action: PrimaryActionButton(
            onPressed: () => ref.invalidate(recurringExpensesStreamProvider),
            child: Text(tr('retry')),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense recurring,
  ) async {
    HapticUtils.selection();
    final notifier = ref.read(recurringExpensesControllerProvider.notifier);
    try {
      await notifier.toggleActive(recurring);
    } catch (e) {
      if (context.mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('recurring.error', args: [e.toString()]),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onError,
                  ),
            ),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _generateExpense(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense recurring,
  ) async {
    HapticUtils.mediumImpact();
    final notifier = ref.read(recurringExpensesControllerProvider.notifier);

    try {
      await notifier.generateNow(recurring);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('recurring.generated'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('recurring.error', args: [e.toString()]),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onError,
                  ),
            ),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
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
    final confirmed = await showConfirmActionSheet(
      context: context,
      title: tr('recurring.delete_title'),
      message: tr('recurring.delete_message'),
      cancelLabel: tr('cancel'),
      confirmLabel: tr('delete'),
      isDestructive: true,
    );

    if (confirmed) {
      HapticUtils.mediumImpact();
      final notifier = ref.read(recurringExpensesControllerProvider.notifier);
      try {
        await notifier.delete(recurring.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('recurring.deleted'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final cs = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr('recurring.error', args: [e.toString()]),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onError,
                    ),
              ),
              backgroundColor: cs.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
    final cs = Theme.of(context).colorScheme;
    final accent = recurring.type.isIncome ? cs.primary : cs.error;
    final dateFormat = DateFormat.yMMMMd(context.locale.toLanguageTag());

    return EnhancedExpenseCard(
      gradient: recurring.type.isIncome
          ? IncomeGradient.fromScheme(cs)
          : ExpenseGradient.fromScheme(cs),
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(recurring.amount.amount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: accent,
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
                  Icons.repeat_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
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
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
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
                    Icons.schedule_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
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
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(tr('recurring.generate_now')),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                  color: cs.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
