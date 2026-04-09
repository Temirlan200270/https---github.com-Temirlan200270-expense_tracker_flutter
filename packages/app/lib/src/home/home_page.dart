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

  // Упрощенная статистика без конвертации валют для главной страницы
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    // Получаем статистику за текущий месяц
    final statsAsync = ref.watch(_homeStatsProvider);
    final decisionAsync = ref.watch(homeDecisionEngineProvider);
    final recentExpensesAsync = ref.watch(expensesStreamProvider);
    final now = DateTime.now();

    return PrimaryScaffold(
      title: tr('home.title'),
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () => context.push('/analytics'),
          tooltip: tr('analytics.title'),
        ),
        PopupMenuButton(
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
        onPressed: () {
          HapticUtils.mediumImpact();
          context.push('/expenses/new');
        },
        child: const Icon(Icons.add),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(_homeStatsProvider.future),
            ref.refresh(homeDecisionEngineProvider.future),
            ref.refresh(expensesStreamProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero карточка баланса
              Consumer(
                builder: (context, ref, child) {
                  final themeType = ref.watch(appThemeTypeProvider);
                  return statsAsync.when(
                    data: (stats) => BalanceCard(
                      balance: stats.balance,
                      income: stats.totalIncome,
                      expenses: stats.totalExpenses,
                      formatter: formatter,
                      themeType: themeType.name, // 'purple', 'green', 'orange'
                    ),
                    loading: () => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          tr('home.stats_error'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              decisionAsync.when(
                data: (snapshot) => _HomeDecisionEngineCard(
                  snapshot: snapshot,
                  formatter: formatter,
                  now: now,
                )
                    .animate()
                    .fadeIn(duration: 320.ms, delay: 80.ms)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 320.ms,
                      delay: 80.ms,
                      curve: Curves.easeOutCubic,
                    ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (decisionAsync.hasValue) const SizedBox(height: 16),
              // Секция бюджетов
              const BudgetsSummaryWidget(),
              const SizedBox(height: 16),
              // Быстрые действия
              QuickActions(
                onExpense: () {
                  HapticUtils.selection();
                  context.push('/expenses/new', extra: {'type': 'expense'});
                },
                onIncome: () {
                  HapticUtils.selection();
                  context.push('/expenses/new', extra: {'type': 'income'});
                },
                onRepeatLast: recentExpensesAsync.valueOrNull?.isNotEmpty ==
                        true
                    ? () {
                        HapticUtils.mediumImpact();
                        final last = recentExpensesAsync.valueOrNull!.first;
                        context.push('/expenses/new', extra: {'expense': last});
                      }
                    : null,
                hasLastTransaction:
                    recentExpensesAsync.valueOrNull?.isNotEmpty == true,
              ),
              const SizedBox(height: 16),
              // Последние транзакции
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tr('home.recent_transactions'),
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideX(begin: -0.1, end: 0, duration: 400.ms, delay: 200.ms),
                  ),
                  TextButton(
                    onPressed: () => context.push('/expenses'),
                    child: Text(tr('home.view_all'))
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 250.ms),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              recentExpensesAsync.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long,
                      title: tr('home.no_transactions'),
                      message: tr('home.no_transactions_hint'),
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
                  final recent = expenses.take(5).toList();
                  return Column(
                    children: recent
                        .asMap()
                        .entries
                        .map((entry) {
                          final delay = (50 * entry.key).ms;
                          return _DismissibleTransactionTile(
                            expense: entry.value,
                            formatter: formatter,
                          )
                              .animate()
                              .fadeIn(
                                duration: 300.ms,
                                delay: delay,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 300.ms,
                                delay: delay,
                                curve: Curves.easeOutCubic,
                              );
                        })
                        .toList(),
                  );
                },
                loading: () => const SkeletonList(itemCount: 3),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tr('home.transactions_error'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decision Engine: предиктивный статус + один инсайт с «почему» и уверенностью формулировки.
class _HomeDecisionEngineCard extends StatelessWidget {
  const _HomeDecisionEngineCard({
    required this.snapshot,
    required this.formatter,
    required this.now,
  });

  final HomeDecisionSnapshot snapshot;
  final NumberFormat formatter;
  final DateTime now;

  /// Лид с учётом тренда: stable → прежние ключи; иначе суффикс accel / slow.
  static String _leadTrKey(
    HomeBehaviorInsight insight,
    TrendDirection trend,
  ) {
    final tier = switch (insight.confidence) {
      InsightConfidenceTier.high => 'high',
      InsightConfidenceTier.medium => 'medium',
      InsightConfidenceTier.low => 'low',
    };
    if (trend == TrendDirection.stable) {
      return insight.variant == HomeInsightVariant.overallOverspend
          ? 'home.decision.insight_overall_lead_$tier'
          : 'home.decision.insight_category_lead_$tier';
    }
    final suffix =
        trend == TrendDirection.accelerating ? 'accel' : 'slow';
    return insight.variant == HomeInsightVariant.overallOverspend
        ? 'home.decision.insight_overall_lead_${tier}_$suffix'
        : 'home.decision.insight_category_lead_${tier}_$suffix';
  }

  /// Одна строка: отклонение + тренд + runway (без дубля с блоком прогноза).
  static String? _synthesisLine(HomeDecisionSnapshot snapshot) {
    final insight = snapshot.behaviorInsight;
    final runway = snapshot.runwayDays;
    if (insight == null || runway == null) return null;
    final days = '$runway';
    final trend = snapshot.spendingTrend;
    final isOverall =
        insight.variant == HomeInsightVariant.overallOverspend;
    if (isOverall) {
      final key = switch (trend) {
        TrendDirection.accelerating =>
          'home.decision.synthesis_overall_runway_accel',
        TrendDirection.slowing => 'home.decision.synthesis_overall_runway_slow',
        TrendDirection.stable => 'home.decision.synthesis_overall_runway_stable',
      };
      return tr(key, namedArgs: {'days': days});
    }
    final cat = insight.topContributor?.categoryName ?? '—';
    final key = switch (trend) {
      TrendDirection.accelerating =>
        'home.decision.synthesis_category_runway_accel',
      TrendDirection.slowing => 'home.decision.synthesis_category_runway_slow',
      TrendDirection.stable => 'home.decision.synthesis_category_runway_stable',
    };
    return tr(key, namedArgs: {'days': days, 'category': cat});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (Color tint, IconData icon, Color iconColor, String stateKey) =
        switch (snapshot.stateTier) {
      HomeFinancialStateTier.stable => (
          cs.primary.withValues(alpha: 0.12),
          Icons.shield_moon_outlined,
          cs.primary,
          'home.decision.state_stable',
        ),
      HomeFinancialStateTier.caution => (
          cs.tertiary.withValues(alpha: 0.14),
          Icons.visibility_outlined,
          cs.tertiary,
          'home.decision.state_caution',
        ),
      HomeFinancialStateTier.danger => (
          cs.error.withValues(alpha: 0.12),
          Icons.warning_amber_rounded,
          cs.error,
          'home.decision.state_danger',
        ),
    };

    final insight = snapshot.behaviorInsight;
    final timeLabel =
        DateFormat.Hm(context.locale.toLanguageTag()).format(now);
    final excessPct = insight != null
        ? ((insight.deviation.velocityRatio - 1) * 100)
            .round()
            .clamp(1, 500)
            .toString()
        : '';

    final synthesis = _synthesisLine(snapshot);
    final hasForecastBlock = snapshot.forecast != null ||
        (snapshot.runwayDays != null && synthesis == null);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('home.decision.title'),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (snapshot.spendingTrend == TrendDirection.accelerating)
                  Icon(
                    Icons.trending_up_rounded,
                    color: cs.error.withValues(alpha: 0.9),
                    size: 26,
                  )
                else if (snapshot.spendingTrend == TrendDirection.slowing)
                  Icon(
                    Icons.trending_down_rounded,
                    color: cs.primary.withValues(alpha: 0.9),
                    size: 26,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tr(stateKey),
              style: textTheme.titleSmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (insight == null &&
                (snapshot.spendingTrend == TrendDirection.accelerating ||
                    snapshot.spendingTrend == TrendDirection.slowing)) ...[
              const SizedBox(height: 8),
              Text(
                snapshot.spendingTrend == TrendDirection.accelerating
                    ? tr('home.decision.trend_accelerating')
                    : tr('home.decision.trend_slowing'),
                style: textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: snapshot.spendingTrend == TrendDirection.accelerating
                      ? cs.error.withValues(alpha: 0.88)
                      : cs.primary.withValues(alpha: 0.88),
                ),
              ),
            ],
            if (insight != null) ...[
              const SizedBox(height: 14),
              Text(
                insight.variant == HomeInsightVariant.categoryFocus
                    ? tr(
                        _leadTrKey(insight, snapshot.spendingTrend),
                        namedArgs: {
                          'category':
                              insight.topContributor?.categoryName ?? '—',
                        },
                      )
                    : tr(_leadTrKey(insight, snapshot.spendingTrend)),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  'home.decision.insight_detail',
                  namedArgs: {
                    'time': timeLabel,
                    'usual': formatter.format(insight.baseline.expectedUntilNow),
                    'current':
                        formatter.format(insight.baseline.spentTodayUntilNow),
                    'excess': excessPct,
                  },
                ),
                style: textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: cs.onSurface.withValues(alpha: 0.88),
                ),
              ),
              if (insight.variant == HomeInsightVariant.overallOverspend &&
                  insight.topContributor != null &&
                  insight.topContributor!.contribution > 0.01)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    tr(
                      'home.decision.cause_line',
                      namedArgs: {
                        'category': insight.topContributor!.categoryName,
                        'amount': formatter
                            .format(insight.topContributor!.contribution),
                      },
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: cs.tertiary,
                    ),
                  ),
                ),
              if (synthesis != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    synthesis,
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.92),
                    ),
                  ),
                ),
            ],
            if (hasForecastBlock) ...[
              const SizedBox(height: 14),
              Text(
                tr('home.decision.forecast_heading'),
                style: textTheme.labelLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              if (snapshot.forecast != null)
                Text(
                  tr(
                    'home.decision.forecast_expenses',
                    namedArgs: {
                      'amount':
                          formatter.format(snapshot.forecast!.projectedExpenses),
                    },
                  ),
                  style: textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              if (snapshot.runwayDays != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr(
                      'home.decision.runway_days',
                      namedArgs: {
                        'days': '${snapshot.runwayDays}',
                      },
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: cs.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Транзакция с возможностью удаления
class _DismissibleTransactionTile extends ConsumerWidget {
  const _DismissibleTransactionTile({
    required this.expense,
    required this.formatter,
  });

  final Expense expense;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = expense.type.isIncome ? Colors.green : Colors.red;
    final dateLabel = DateFormat.yMd(context.locale.toLanguageTag())
        .format(expense.occurredAt);
    final timeLabel = DateFormat.Hm().format(expense.occurredAt);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => _deleteExpense(context, ref),
      child: EnhancedExpenseCard(
        gradient: expense.type.isIncome ? IncomeGradient() : ExpenseGradient(),
        onLongPress: () => _showContextMenu(context, ref),
        onTap: () => context.push('/expenses'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(
                  expense.type.isIncome
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatter.format(expense.amount.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$dateLabel • $timeLabel',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (expense.note != null && expense.note!.isNotEmpty)
                      Text(
                        expense.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                onPressed: () => _showDeleteDialog(context, ref),
                tooltip: tr('delete'),
              ),
            ],
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
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
