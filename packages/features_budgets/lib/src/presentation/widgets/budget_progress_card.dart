import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_models/shared_models.dart';

/// Карточка с прогрессом бюджета
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.budgetWithSpending,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.compact = false,
  });

  final BudgetWithSpending budgetWithSpending;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact; // Компактный режим для главной страницы

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = budgetWithSpending.budget;
    final progress = budgetWithSpending.progress;
    final status = budgetWithSpending.status;

    // Цвета в зависимости от статуса
    final progressColor = _getStatusColor(status, theme);
    final backgroundColor = _getBackgroundColor(status, theme);

    if (compact) {
      return _buildCompact(context, theme, progressColor, backgroundColor);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и меню
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (budgetWithSpending.categoryName != null)
                          Text(
                            budgetWithSpending.categoryName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildPeriodChip(context, budget.period),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 20),
                                const SizedBox(width: 8),
                                Text(tr('edit')),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Text(tr('delete'), style: TextStyle(color: theme.colorScheme.error)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Прогресс-бар
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              )
                  .animate()
                  .fadeIn(
                      duration: 220.ms,
                      delay: 120.ms,
                      curve: Curves.easeOutCubic)
                  .scaleX(
                      begin: 0,
                      end: 1,
                      duration: 320.ms,
                      delay: 120.ms,
                      curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              // Суммы
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('budget.spent'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatMoney(budgetWithSpending.spentInCents, budget.limit.currencyCode),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tr('budget.limit'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatMoney(budget.limit.amountInCents, budget.limit.currencyCode),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Остаток или превышение
              const SizedBox(height: 8),
              _buildRemainingInfo(context, theme, progressColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    ThemeData theme,
    Color progressColor,
    Color backgroundColor,
  ) {
    final budget = budgetWithSpending.budget;
    final progress = budgetWithSpending.progress;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  budget.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          )
              .animate()
              .fadeIn(
                  duration: 200.ms,
                  delay: 70.ms,
                  curve: Curves.easeOutCubic)
              .scaleX(
                  begin: 0,
                  end: 1,
                  duration: 280.ms,
                  delay: 70.ms,
                  curve: Curves.easeOutCubic),
          const SizedBox(height: 4),
          Text(
            '${_formatMoney(budgetWithSpending.spentInCents, budget.limit.currencyCode)} / ${_formatMoney(budget.limit.amountInCents, budget.limit.currencyCode)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(BuildContext context, BudgetPeriod period) {
    final isRussian = context.locale.languageCode == 'ru';
    return Chip(
      label: Text(
        isRussian ? period.displayName : period.displayNameEn,
        style: const TextStyle(fontSize: 12),
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildRemainingInfo(BuildContext context, ThemeData theme, Color progressColor) {
    final remaining = budgetWithSpending.remainingInCents;
    final currency = budgetWithSpending.budget.limit.currencyCode;

    if (budgetWithSpending.isOverBudget) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, 
                 size: 16, 
                 color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 4),
            Text(
              '${tr('budget.exceeded_by')} ${_formatMoney(remaining.abs(), currency)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      '${tr('budget.remaining')}: ${_formatMoney(remaining, currency)}',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: progressColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Color _getStatusColor(BudgetStatus status, ThemeData theme) {
    switch (status) {
      case BudgetStatus.normal:
        return Colors.green;
      case BudgetStatus.warning:
        return Colors.orange;
      case BudgetStatus.exceeded:
        return theme.colorScheme.error;
    }
  }

  Color _getBackgroundColor(BudgetStatus status, ThemeData theme) {
    switch (status) {
      case BudgetStatus.normal:
        return theme.colorScheme.surface;
      case BudgetStatus.warning:
        return Colors.orange.withOpacity(0.1);
      case BudgetStatus.exceeded:
        return theme.colorScheme.errorContainer.withOpacity(0.3);
    }
  }

  String _formatMoney(int amountInCents, String currencyCode) {
    final amount = amountInCents / 100;
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 0,
    );
    return formatter.format(amount);
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

