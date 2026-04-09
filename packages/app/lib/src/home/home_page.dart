import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_analytics/features_analytics.dart';
import 'package:features_budgets/features_budgets.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import 'home_decision_hero_helper.dart';
import 'home_hero_block.dart';

// Провайдер для статистики на главной странице (за месяц)
final _homeStatsProvider =
    FutureProvider.autoDispose<AnalyticsStats>((ref) async {
  final expenses = await ref.watch(expensesStreamProvider.future);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1);
  final lastDay = DateTime(now.year, now.month + 1, 0);
  final to = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);

  final filtered = expenses.where((expense) {
    if (expense.occurredAt.isBefore(from)) return false;
    if (expense.occurredAt.isAfter(to)) return false;
    return true;
  }).toList();

  double totalIncome = 0;
  double totalExpenses = 0;
  int incomeCount = 0;
  int expenseCount = 0;

  for (final expense in filtered) {
    if (expense.type.isIncome) {
      totalIncome += expense.amount.amount;
      incomeCount++;
    } else {
      totalExpenses += expense.amount.amount;
      expenseCount++;
    }
  }

  return AnalyticsStats(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    balance: totalIncome - totalExpenses,
    incomeCount: incomeCount,
    expenseCount: expenseCount,
  );
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: tr('settings'),
          onPressed: () {
            HapticUtils.selection();
            context.push('/settings');
          },
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.analytics_outlined),
          onPressed: () => context.push('/analytics'),
          tooltip: tr('analytics.title'),
        ),
        PopupMenuButton<void>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: Text(tr('budget.title')),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/budgets');
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(tr('debts.title')),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/debts');
                },
              ),
            ),
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
                leading: const Icon(Icons.repeat),
                title: Text(tr('recurring.title')),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/recurring');
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
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    final statsAsync = ref.watch(_homeStatsProvider);
    final decisionAsync = ref.watch(homeDecisionEngineProvider);
    final recentExpensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(_homeStatsProvider.future),
            ref.refresh(homeDecisionEngineProvider.future),
            ref.refresh(expensesStreamProvider.future),
          ]);
        },
        child: recentExpensesAsync.when(
          data: (allExpenses) {
            final globalEmpty = allExpenses.isEmpty;
            final recentForHome = allExpenses.take(5).toList();
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: globalEmpty
                      ? HomeHeroBlock(
                          topBar: _topBar(context),
                          stateTitle: tr('home.ftue.title'),
                          microAction: tr('home.hero.ftue_micro'),
                          balanceLabel: tr('home.hero.month_balance'),
                          balanceAmount: formatter.format(0),
                          accentColor:
                              Theme.of(context).colorScheme.primary,
                          onPrimaryAction: () =>
                              context.push('/expenses/new'),
                          primaryActionLabel: tr('home.hero.new_operation'),
                          secondaryAction: TextButton.icon(
                            onPressed: () {
                              HapticUtils.selection();
                              context.push('/import');
                            },
                            icon: const Icon(Icons.upload_file, size: 20),
                            label: Text(tr('home.ftue.import_cta')),
                          ),
                        )
                          .animate()
                          .fadeIn(
                            duration: AppMotion.standard,
                            curve: AppMotion.curve,
                          )
                          .slideY(
                            begin: 0.04,
                            end: 0,
                            duration: AppMotion.screen,
                            curve: AppMotion.curve,
                          )
                      : statsAsync.when(
                          data: (stats) => decisionAsync.when(
                            data: (snapshot) {
                              final narrative =
                                  HomeDecisionHeroHelper.build(
                                colorScheme:
                                    Theme.of(context).colorScheme,
                                snapshot: snapshot,
                                formatter: formatter,
                              );
                              return HomeHeroBlock(
                                topBar: _topBar(context),
                                stateTitle: narrative.stateTitle,
                                microAction: narrative.microAction,
                                detailLine: narrative.detailLine,
                                balanceLabel:
                                    tr('home.hero.month_balance'),
                                balanceAmount:
                                    formatter.format(stats.balance),
                                accentColor: narrative.accentColor,
                                onPrimaryAction: () =>
                                    context.push('/expenses/new'),
                                primaryActionLabel:
                                    tr('home.hero.new_operation'),
                              );
                            },
                            loading: () => _HeroLoadingShell(
                              topBar: _topBar(context),
                            ),
                            error: (_, __) => HomeHeroBlock(
                              topBar: _topBar(context),
                              stateTitle: tr('home.decision.state_stable'),
                              microAction: tr(
                                'home.decision.micro_action_stable',
                              ),
                              balanceLabel:
                                  tr('home.hero.month_balance'),
                              balanceAmount:
                                  formatter.format(stats.balance),
                              accentColor: Theme.of(context)
                                  .colorScheme
                                  .primary,
                              onPrimaryAction: () =>
                                  context.push('/expenses/new'),
                              primaryActionLabel:
                                  tr('home.hero.new_operation'),
                            ),
                          ),
                          loading: () => _HeroLoadingShell(
                            topBar: _topBar(context),
                          ),
                          error: (error, _) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              tr('home.stats_error'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error,
                                  ),
                            ),
                          ),
                        ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (globalEmpty) ...[
                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                        ],
                        const BudgetsSummaryWidget(),
                        if (!globalEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr('home.recent_transactions'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/expenses'),
                                child: Text(tr('home.view_all')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!globalEmpty)
                  SliverList.separated(
                    itemCount: recentForHome.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.15),
                    ),
                    itemBuilder: (context, index) {
                      final expense = recentForHome[index];
                      return _HomeFeedTile(
                        expense: expense,
                        formatter: formatter,
                        showDayHeader: _shouldShowDayHeader(
                          recentForHome,
                          index,
                        ),
                        dayHeaderText: _dayHeaderText(
                          context,
                          expense.occurredAt,
                        ),
                      )
                          .animate()
                          .fadeIn(
                            duration: AppMotion.standard,
                            delay: (AppMotion.staggerInterval * index),
                            curve: AppMotion.curve,
                          )
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            duration: AppMotion.standard,
                            delay: (AppMotion.staggerInterval * index),
                            curve: AppMotion.curve,
                          );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
          loading: () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroLoadingShell(topBar: _topBar(context)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const BudgetsSummaryWidget(),
                      const SizedBox(height: 16),
                      const SkeletonList(itemCount: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                tr('home.transactions_error'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _shouldShowDayHeader(List<Expense> list, int index) {
    if (index == 0) return true;
    final a = list[index - 1].occurredAt;
    final b = list[index].occurredAt;
    return !_isSameCalendarDay(a, b);
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dayHeaderText(BuildContext context, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    if (target == today) return tr('home.feed.today');
    if (target == today.subtract(const Duration(days: 1))) {
      return tr('home.feed.yesterday');
    }
    return DateFormat.yMMMd(context.locale.toLanguageTag()).format(d);
  }
}

/// Плейсхолдер hero при загрузке decision/stats.
class _HeroLoadingShell extends StatelessWidget {
  const _HeroLoadingShell({required this.topBar});

  final Widget topBar;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 28),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topBar,
          const SizedBox(height: 32),
          Container(
            height: 20,
            width: 180,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            height: 48,
            width: 140,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}

/// Плоская строка ленты (без «коробочной» карточки).
class _HomeFeedTile extends ConsumerWidget {
  const _HomeFeedTile({
    required this.expense,
    required this.formatter,
    required this.showDayHeader,
    required this.dayHeaderText,
  });

  final Expense expense;
  final NumberFormat formatter;
  final bool showDayHeader;
  final String dayHeaderText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isIncome = expense.type.isIncome;
    final amountColor =
        isIncome ? cs.primary : cs.error;
    final timeLabel =
        DateFormat.Hm(context.locale.toLanguageTag())
            .format(expense.occurredAt);
    final title = (expense.note != null && expense.note!.trim().isNotEmpty)
        ? expense.note!.trim()
        : (isIncome ? tr('home.feed.income') : tr('home.feed.expense'));

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => _deleteExpense(context, ref),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/expenses'),
          onLongPress: () => _showContextMenu(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDayHeader) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      dayHeaderText,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatter.format(expense.amount.amount),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: amountColor,
                            letterSpacing: -0.5,
                          ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: cs.onSurface.withValues(alpha: 0.35),
                        size: 22,
                      ),
                      onPressed: () => _showDeleteDialog(context, ref),
                      tooltip: tr('delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.error,
                ),
                child: Text(tr('delete')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref) async {
    HapticUtils.mediumImpact();
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
    final cs = Theme.of(context).colorScheme;
    final isIncome = expense.type.isIncome;
    final amountColor = isIncome ? cs.primary : cs.error;

    showModalBottomSheet<void>(
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
                color: cs.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: amountColor.withValues(alpha: 0.15),
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: amountColor,
                ),
              ),
              title: Text(
                formatter.format(expense.amount.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              subtitle: Text(
                DateFormat.yMMMMd(context.locale.toLanguageTag())
                    .format(expense.occurredAt),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(tr('expenses.edit.title')),
              onTap: () {
                HapticUtils.selection();
                Navigator.pop(context);
                context.push('/expenses/new', extra: {'expense': expense});
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(tr('expenses.duplicate.title')),
              onTap: () async {
                HapticUtils.selection();
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
                  HapticUtils.success();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('expenses.duplicate.success')),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: cs.error),
              title: Text(
                tr('delete'),
                style: TextStyle(color: cs.error),
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
