import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/budgets_providers.dart';
import '../widgets/budget_progress_card.dart';

/// Страница списка бюджетов
class BudgetsListPage extends ConsumerWidget {
  const BudgetsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsWithSpendingProvider);
    final theme = Theme.of(context);

    return PrimaryScaffold(
      title: tr('budget.title'),
      contract: SssScreenContract.configuration,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInfoDialog(context),
          tooltip: tr('budget.info'),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => context.push('/budgets/new'),
        icon: const Icon(Icons.add),
        label: Text(tr('budget.add')),
      ),
      child: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(tr('error_occurred')),
              TextButton(
                onPressed: () => ref.invalidate(budgetsWithSpendingProvider),
                child: Text(tr('retry')),
              ),
            ],
          ),
        ),
        data: (budgets) {
          if (budgets.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(budgetsWithSpendingProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                return BudgetProgressCard(
                  budgetWithSpending: budget,
                  onTap: () => context.push('/budgets/${budget.budget.id}'),
                  onEdit: () => context.push('/budgets/${budget.budget.id}/edit'),
                  onDelete: () => _confirmDelete(context, ref, budget.budget.id, budget.budget.name),
                )
                    .animate()
                    .fadeIn(
                        duration: 200.ms,
                        delay: (28 * index).ms,
                        curve: Curves.easeOutCubic)
                    .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 220.ms,
                        delay: (28 * index).ms,
                        curve: Curves.easeOutCubic);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: tr('budget.empty_title'),
      message: tr('budget.empty_message'),
      action: FilledButton.icon(
        onPressed: () => context.push('/budgets/new'),
        icon: const Icon(Icons.add),
        label: Text(tr('budget.create')),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('budget.delete_title')),
        content: Text(tr('budget.delete_message', args: [name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(budgetsControllerProvider.notifier).deleteBudget(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('budget.deleted'))),
        );
      }
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('budget.info_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, Colors.green, tr('budget.info_normal')),
            const SizedBox(height: 8),
            _buildInfoRow(context, Colors.orange, tr('budget.info_warning')),
            const SizedBox(height: 8),
            _buildInfoRow(context, Theme.of(context).colorScheme.error, tr('budget.info_exceeded')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('ok')),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

