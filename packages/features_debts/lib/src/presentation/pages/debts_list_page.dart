import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/debts_providers.dart';
import '../widgets/debt_card.dart';

/// Страница списка долгов с двумя вкладками
class DebtsListPage extends ConsumerStatefulWidget {
  const DebtsListPage({super.key});

  @override
  ConsumerState<DebtsListPage> createState() => _DebtsListPageState();
}

class _DebtsListPageState extends ConsumerState<DebtsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PrimaryScaffold(
      title: tr('debts.title'),
      contract: SssScreenContract.configuration,
      appBarBottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: Icon(Icons.arrow_downward_rounded, color: cs.primary),
            text: tr('debts.they_owe'),
          ),
          Tab(
            icon: Icon(Icons.arrow_upward_rounded, color: cs.error),
            text: tr('debts.i_owe'),
          ),
        ],
      ),
      fab: FloatingActionButton.extended(
        onPressed: () => context.push('/debts/new'),
        icon: const Icon(Icons.add),
        label: Text(tr('debts.add')),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _DebtsTab(type: DebtType.theyOwe),
          _DebtsTab(type: DebtType.iOwe),
        ],
      ),
    );
  }
}

class _DebtsTab extends ConsumerWidget {
  const _DebtsTab({required this.type});

  final DebtType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = type == DebtType.theyOwe
        ? ref.watch(debtsTheyOweProvider)
        : ref.watch(debtsIOweProvider);

    return debtsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(tr('error_occurred')),
            TextButton(
              onPressed: () {
                if (type == DebtType.theyOwe) {
                  ref.invalidate(debtsTheyOweProvider);
                } else {
                  ref.invalidate(debtsIOweProvider);
                }
              },
              child: Text(tr('retry')),
            ),
          ],
        ),
      ),
      data: (debts) {
        if (debts.isEmpty) {
          return EmptyState(
            icon: type == DebtType.theyOwe
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            title: tr('debts.empty_title'),
            message: type == DebtType.theyOwe
                ? tr('debts.empty_they_owe')
                : tr('debts.empty_i_owe'),
            action: FilledButton.icon(
              onPressed: () {
                // Сохраняем тип в state для использования в форме
                context.push('/debts/new', extra: {'type': type});
              },
              icon: const Icon(Icons.add),
              label: Text(tr('debts.add')),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (type == DebtType.theyOwe) {
              ref.invalidate(debtsTheyOweProvider);
            } else {
              ref.invalidate(debtsIOweProvider);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              return DebtCard(
                debt: debts[index],
                onTap: () => context.push('/debts/${debts[index].id}'),
                onRepay: () => _showRepayDialog(context, ref, debts[index]),
                onDelete: () => _confirmDelete(context, ref, debts[index]),
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
    );
  }

  Future<void> _showRepayDialog(
      BuildContext context, WidgetRef ref, Debt debt) async {
    final controller = TextEditingController();
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(debt.totalAmount.currencyCode),
      decimalDigits: 0,
    );

    final result = await showDialog<Money?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('debts.repay_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('debts.repay_message', args: [
              debt.personName,
              formatter.format(debt.remainingAmount.amount),
            ])),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: tr('debts.repay_amount'),
                hintText: formatter.format(debt.remainingAmount.amount),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                controller.text =
                    debt.remainingAmount.amount.toStringAsFixed(0);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(tr('debts.repay_full')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final amountStr = controller.text.trim();
              if (amountStr.isEmpty) {
                Navigator.of(context).pop();
                return;
              }

              final amount = double.tryParse(amountStr);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('debts.invalid_amount'))),
                );
                return;
              }

              final repayment = Money(
                amountInCents: (amount * 100).round(),
                currencyCode: debt.totalAmount.currencyCode,
              );

              Navigator.of(context).pop(repayment);
            },
            child: Text(tr('debts.repay')),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await ref.read(debtsControllerProvider.notifier).repayDebt(
            debtId: debt.id,
            amount: result,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('debts.repaid_success'))),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('debts.delete_title')),
        content: Text(tr('debts.delete_message', args: [debt.personName])),
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
      await ref.read(debtsControllerProvider.notifier).deleteDebt(debt.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('debts.deleted'))),
        );
      }
    }
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'KZT':
        return '₸';
      case 'RUB':
        return '₽';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return code;
    }
  }
}
