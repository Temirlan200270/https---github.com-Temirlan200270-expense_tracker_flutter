import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import 'home_feed_tile_model.dart';
import 'home_layout_shell.dart';
import 'home_more_sheet.dart';

/// Карточка операции в ленте: рендерит [ExpenseTileModel] (domain mapping уже выполнен).
///
/// Нет `ref.watch(categoriesStreamProvider)` — данные приходят готовыми.
class HomeFeedCard extends ConsumerStatefulWidget {
  const HomeFeedCard({
    super.key,
    required this.tile,
    required this.formatter,
    required this.showDayHeader,
    required this.dayHeaderText,
  });

  final ExpenseTileModel tile;
  final NumberFormat formatter;
  final bool showDayHeader;
  final String dayHeaderText;

  @override
  ConsumerState<HomeFeedCard> createState() => _HomeFeedCardState();
}

class _HomeFeedCardState extends ConsumerState<HomeFeedCard> {
  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final expense = tile.expense;
    final cs = Theme.of(context).colorScheme;
    final amountColor = tile.isIncome ? cs.tertiary : cs.error;
    final timeLabel =
        DateFormat.Hm(context.locale.toLanguageTag())
            .format(expense.occurredAt);

    final iconData = tile.resolveIcon();
    final iconBg = tile.resolveIconBackground(cs);
    final iconFg = tile.resolveIconForeground(cs);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: HomeLayoutSpacing.s20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_rounded, color: cs.onError),
      ),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => _deleteExpense(context),
      child: PressableScale(
        child: EnhancedExpenseCard(
          margin: EdgeInsets.zero,
          gradient: null,
          color: cs.surface,
          onTap: () {
            HapticUtils.selection();
            context.go(AppRoutes.expenses);
          },
          onLongPress: () => _showContextMenu(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeLayoutSpacing.s16,
              vertical: HomeLayoutSpacing.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showDayHeader) ...[
                  Text(
                    widget.dayHeaderText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.35,
                        ),
                  ),
                  SizedBox(height: HomeLayoutSpacing.s12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconData, color: iconFg, size: 22),
                    ),
                    SizedBox(width: HomeLayoutSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tile.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (tile.categoryName != null) ...[
                            SizedBox(height: HomeLayoutSpacing.s8),
                            Text(
                              tile.categoryName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${tile.isIncome ? '+' : '−'} ${widget.formatter.format(expense.amount.amount)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: amountColor,
                                letterSpacing: -0.6,
                              ),
                        ),
                        Text(
                          timeLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
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

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr('expenses.delete.title')),
            content: Text(tr('expenses.delete.message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                ),
                child: Text(tr('delete')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteExpense(BuildContext context) async {
    final expense = widget.tile.expense;
    HapticUtils.mediumImpact();
    final repo = ref.read(expensesRepositoryProvider);
    await repo.softDelete(expense.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('expenses.delete.success')),
          duration: const Duration(seconds: 4),
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

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await _confirmDelete(context);
    if (confirmed && context.mounted) {
      await _deleteExpense(context);
    }
  }

  void _showContextMenu(BuildContext context) {
    final expense = widget.tile.expense;
    final cs = Theme.of(context).colorScheme;
    final amountColor = widget.tile.isIncome ? cs.primary : cs.error;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HomeLayoutSpacing.s20,
              HomeLayoutSpacing.s8,
              HomeLayoutSpacing.s20,
              HomeLayoutSpacing.s12,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: amountColor.withValues(alpha: 0.15),
                  child: Icon(
                    widget.tile.isIncome
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: amountColor,
                  ),
                ),
                SizedBox(width: HomeLayoutSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.formatter.format(expense.amount.amount),
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: amountColor,
                            ),
                      ),
                      Text(
                        DateFormat.yMMMMd(sheetContext.locale.toLanguageTag())
                            .format(expense.occurredAt),
                        style: Theme.of(sheetContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          HomeSheetAction(
            icon: Icons.edit_rounded,
            label: tr('expenses.edit.title'),
            onTap: () {
              HapticUtils.selection();
              Navigator.pop(sheetContext);
              context.push(
                AppRoutes.expensesNew,
                extra: {'expense': expense},
              );
            },
          ),
          HomeSheetAction(
            icon: Icons.copy_rounded,
            label: tr('expenses.duplicate.title'),
            onTap: () async {
              HapticUtils.selection();
              Navigator.pop(sheetContext);
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
          HomeSheetAction(
            icon: Icons.delete_outline_rounded,
            label: tr('delete'),
            foregroundColor: cs.error,
            onTap: () {
              Navigator.pop(sheetContext);
              _showDeleteDialog(context);
            },
          ),
          SizedBox(height: HomeLayoutSpacing.s8),
        ],
      ),
    );
  }
}
