import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/expenses_providers.dart';
import '../../controllers/expenses_list_controller.dart';
import '../widgets/expense_filters_sheet.dart';
import '../widgets/expense_search_field.dart';

/// Группировка расходов
enum ExpenseGrouping {
  none,
  byDate,
  byCategory,
  byType,
}

/// Провайдер для текущей группировки
final expenseGroupingProvider =
    StateProvider<ExpenseGrouping>((ref) => ExpenseGrouping.byDate);

class ExpensesListPage extends ConsumerWidget {
  const ExpensesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final grouping = ref.watch(expenseGroupingProvider);
    final formatter = NumberFormat.simpleCurrency(
        name: currencyCode, locale: context.locale.toLanguageTag());

    final hasActiveFilters = ref.watch(expenseFilterProvider.select(
      (filter) =>
          filter.from != null ||
          filter.to != null ||
          filter.type != null ||
          filter.categoryIds.isNotEmpty ||
          (filter.searchTerm != null && filter.searchTerm!.isNotEmpty),
    ));

    return PrimaryScaffold(
      title: tr('expenses.list.title'),
      actions: [
        // Кнопка группировки
        PopupMenuButton<ExpenseGrouping>(
          icon: const Icon(Icons.sort),
          tooltip: tr('expenses.grouping.title'),
          onSelected: (value) {
            ref.read(expenseGroupingProvider.notifier).state = value;
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ExpenseGrouping.none,
              child: Row(
                children: [
                  if (grouping == ExpenseGrouping.none)
                    const Icon(Icons.check, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(tr('expenses.grouping.none')),
                ],
              ),
            ),
            PopupMenuItem(
              value: ExpenseGrouping.byDate,
              child: Row(
                children: [
                  if (grouping == ExpenseGrouping.byDate)
                    const Icon(Icons.check, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(tr('expenses.grouping.by_date')),
                ],
              ),
            ),
            PopupMenuItem(
              value: ExpenseGrouping.byCategory,
              child: Row(
                children: [
                  if (grouping == ExpenseGrouping.byCategory)
                    const Icon(Icons.check, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(tr('expenses.grouping.by_category')),
                ],
              ),
            ),
            PopupMenuItem(
              value: ExpenseGrouping.byType,
              child: Row(
                children: [
                  if (grouping == ExpenseGrouping.byType)
                    const Icon(Icons.check, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(tr('expenses.grouping.by_type')),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              if (hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const ExpenseFiltersSheet(),
            );
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.category),
                title: Text(tr('categories.title')),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/categories');
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: Text(tr('analytics.title')),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/analytics');
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.upload_file),
                title: Text(tr('export.title')),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/export');
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.download),
                title: Text(tr('import.title')),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/import');
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: Text(tr('settings')),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
            ),
          ],
        ),
      ],
      fab: FloatingActionButton(
        onPressed: () => context.push('/expenses/new'),
        child: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: const ExpenseSearchField()
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.1, end: 0, duration: 300.ms),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(expensesListControllerProvider.notifier).refresh(),
              child: expensesAsync.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long,
                      title: tr('expenses.list.empty'),
                      message: tr('expenses.list.empty_hint'),
                      action: FilledButton.icon(
                        onPressed: () {
                          HapticUtils.selection();
                          context.push('/expenses/new');
                        },
                        icon: const Icon(Icons.add),
                        label: Text(tr('expenses.form.title')),
                      ),
                    );
                  }

                  return categoriesAsync.when(
                    data: (categories) {
                      final categoryMap = {for (var c in categories) c.id: c};
                      return _GroupedExpensesList(
                        expenses: expenses,
                        categoryMap: categoryMap,
                        grouping: grouping,
                        formatter: formatter,
                      );
                    },
                    loading: () => const SkeletonList(itemCount: 5),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  );
                },
                loading: () => const SkeletonList(itemCount: 5),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedExpensesList extends ConsumerWidget {
  const _GroupedExpensesList({
    required this.expenses,
    required this.categoryMap,
    required this.grouping,
    required this.formatter,
  });

  final List<Expense> expenses;
  final Map<String, Category> categoryMap;
  final ExpenseGrouping grouping;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (grouping == ExpenseGrouping.none) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return _DismissibleExpenseTile(
            expense: expense,
            category: expense.categoryId != null
                ? categoryMap[expense.categoryId!]
                : null,
            formatter: formatter,
          )
              .animate()
              .fadeIn(duration: 150.ms, delay: (15 * index).ms)
              .slideY(begin: 0.05, end: 0, duration: 150.ms, delay: (15 * index).ms);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: expenses.length,
      );
    }

    final groups = _groupExpenses(expenses, grouping, categoryMap);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _ExpenseGroup(
          title: group.title,
          subtitle: group.subtitle,
          expenses: group.expenses,
          categoryMap: categoryMap,
          formatter: formatter,
          color: group.color,
        )
            .animate()
            .fadeIn(duration: 150.ms, delay: (20 * index).ms)
            .slideY(begin: 0.05, end: 0, duration: 150.ms, delay: (20 * index).ms);
      },
    );
  }

  List<_ExpenseGroupData> _groupExpenses(
    List<Expense> expenses,
    ExpenseGrouping grouping,
    Map<String, Category> categoryMap,
  ) {
    switch (grouping) {
      case ExpenseGrouping.byDate:
        return _groupByDate(expenses);
      case ExpenseGrouping.byCategory:
        return _groupByCategory(expenses, categoryMap);
      case ExpenseGrouping.byType:
        return _groupByType(expenses);
      case ExpenseGrouping.none:
        return [];
    }
  }

  List<_ExpenseGroupData> _groupByDate(List<Expense> expenses) {
    final Map<String, List<Expense>> grouped = {};

    for (final expense in expenses) {
      final date = DateTime(expense.occurredAt.year, expense.occurredAt.month,
          expense.occurredAt.day);
      final key = date.toIso8601String();
      grouped.putIfAbsent(key, () => []).add(expense);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((key) {
      final date = DateTime.parse(key);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      String title;
      if (date == today) {
        title = tr('expenses.grouping.today');
      } else if (date == yesterday) {
        title = tr('expenses.grouping.yesterday');
      } else {
        title = DateFormat.yMMMMd().format(date);
      }

      final total = grouped[key]!.fold<double>(0, (sum, e) {
        return sum + (e.type.isExpense ? -e.amount.amount : e.amount.amount);
      });

      return _ExpenseGroupData(
        title: title,
        subtitle: formatter.format(total),
        expenses: grouped[key]!,
        color: total >= 0 ? Colors.green : Colors.red,
      );
    }).toList();
  }

  List<_ExpenseGroupData> _groupByCategory(
      List<Expense> expenses, Map<String, Category> categoryMap) {
    final Map<String?, List<Expense>> grouped = {};

    for (final expense in expenses) {
      grouped.putIfAbsent(expense.categoryId, () => []).add(expense);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return (categoryMap[a]?.name ?? '')
            .compareTo(categoryMap[b]?.name ?? '');
      });

    return sortedKeys.map((key) {
      final category = key != null ? categoryMap[key] : null;
      final total =
          grouped[key]!.fold<double>(0, (sum, e) => sum + e.amount.amount);

      return _ExpenseGroupData(
        title: category?.name ?? tr('expenses.grouping.no_category'),
        subtitle: formatter.format(total),
        expenses: grouped[key]!,
        color: category != null ? Color(category.colorValue) : Colors.grey,
      );
    }).toList();
  }

  List<_ExpenseGroupData> _groupByType(List<Expense> expenses) {
    final incomes = expenses.where((e) => e.type.isIncome).toList();
    final expensesList = expenses.where((e) => e.type.isExpense).toList();

    final result = <_ExpenseGroupData>[];

    if (incomes.isNotEmpty) {
      final total = incomes.fold<double>(0, (sum, e) => sum + e.amount.amount);
      result.add(_ExpenseGroupData(
        title: tr('expenses.form.income'),
        subtitle: formatter.format(total),
        expenses: incomes,
        color: Colors.green,
      ));
    }

    if (expensesList.isNotEmpty) {
      final total =
          expensesList.fold<double>(0, (sum, e) => sum + e.amount.amount);
      result.add(_ExpenseGroupData(
        title: tr('expenses.form.expense'),
        subtitle: formatter.format(total),
        expenses: expensesList,
        color: Colors.red,
      ));
    }

    return result;
  }
}

class _ExpenseGroupData {
  const _ExpenseGroupData({
    required this.title,
    required this.subtitle,
    required this.expenses,
    required this.color,
  });

  final String title;
  final String subtitle;
  final List<Expense> expenses;
  final Color color;
}

class _ExpenseGroup extends StatelessWidget {
  const _ExpenseGroup({
    required this.title,
    required this.subtitle,
    required this.expenses,
    required this.categoryMap,
    required this.formatter,
    required this.color,
  });

  final String title;
  final String subtitle;
  final List<Expense> expenses;
  final Map<String, Category> categoryMap;
  final NumberFormat formatter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
                  .animate()
                  .scaleX(begin: 0, end: 1, duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .slideX(begin: -0.1, end: 0, duration: 300.ms, delay: 100.ms),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 150.ms)
                  .slideX(begin: 0.1, end: 0, duration: 300.ms, delay: 150.ms),
            ],
          ),
        ),
        ...expenses.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DismissibleExpenseTile(
              expense: expense,
              category: expense.categoryId != null
                  ? categoryMap[expense.categoryId!]
                  : null,
              formatter: formatter,
            )
                .animate()
                .fadeIn(duration: 150.ms, delay: (10 * index).ms)
                .slideX(begin: 0.03, end: 0, duration: 150.ms, delay: (10 * index).ms),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DismissibleExpenseTile extends ConsumerWidget {
  const _DismissibleExpenseTile({
    required this.expense,
    required this.category,
    required this.formatter,
  });

  final Expense expense;
  final Category? category;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => _deleteExpense(context, ref),
      child: _ExpenseTile(
        expense: expense,
        category: category,
        amountLabel: formatter.format(expense.amount.amount),
        onDelete: () => _showDeleteDialog(context, ref),
        onLongPress: () => _showContextMenu(context, ref),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('expenses.delete.title')),
            content: Text(tr('expenses.delete.message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(tr('delete')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(expensesRepositoryProvider);
    await repo.softDelete(expense.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('expenses.delete.success')),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: tr('expenses.delete.undo'),
            onPressed: () async {
              await repo.upsertExpense(expense.copyWith(
                isDeleted: false,
                deletedAt: null,
              ));
            },
          ),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDelete(context);
    if (confirmed && context.mounted) {
      await _deleteExpense(context, ref);
    }
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final color = expense.type.isIncome ? Colors.green : Colors.red;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(
                  expense.type.isIncome
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: color,
                ),
              ),
              title: Text(
                formatter.format(expense.amount.amount),
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              subtitle: Text(
                DateFormat.yMMMMd().format(expense.occurredAt),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(tr('expenses.edit.title')),
              onTap: () {
                Navigator.pop(context);
                context.push('/expenses/new', extra: {'expense': expense});
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(tr('expenses.duplicate.title')),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(expensesRepositoryProvider);
                final newExpense = Expense(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: expense.amount,
                  type: expense.type,
                  occurredAt: DateTime.now(),
                  categoryId: expense.categoryId,
                  note: expense.note,
                );
                await repo.upsertExpense(newExpense);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('expenses.duplicate.success'))),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                tr('delete'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.amountLabel,
    this.onDelete,
    this.onLongPress,
  });

  final Expense expense;
  final Category? category;
  final String amountLabel;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = expense.type.isIncome ? Colors.green : Colors.red;
    final dateLabel = DateFormat.Hm().format(expense.occurredAt);

    final categoryColor = category != null ? Color(category!.colorValue) : null;

    return EnhancedExpenseCard(
      gradient: categoryColor != null
          ? CategoryGradient(categoryColor)
          : (expense.type.isIncome ? IncomeGradient() : ExpenseGradient()),
      margin: const EdgeInsets.only(bottom: 8),
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: category != null
                  ? Color(category!.colorValue).withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.2),
              child: Icon(
                expense.type.isIncome ? Icons.trending_up : Icons.trending_down,
                color: category != null ? Color(category!.colorValue) : color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amountLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(category!.colorValue).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category!.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(category!.colorValue),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        expense.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Кнопка удаления
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: onDelete,
              tooltip: tr('delete'),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
