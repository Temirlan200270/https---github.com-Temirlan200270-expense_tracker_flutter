import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_models/shared_models.dart';

/// Карточка долга с прогресс-баром
class DebtCard extends StatelessWidget {
  const DebtCard({
    super.key,
    required this.debt,
    this.onTap,
    this.onRepay,
    this.onDelete,
  });

  final Debt debt;
  final VoidCallback? onTap;
  final VoidCallback? onRepay;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTheyOwe = debt.type == DebtType.theyOwe;
    final progress = debt.progress;
    final isOverdue = debt.isOverdue;

    // Цвета в зависимости от типа
    final primaryColor = isTheyOwe ? Colors.green : Colors.red;
    final backgroundColor =
        isTheyOwe ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);

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
                        Row(
                          children: [
                            Icon(
                              isTheyOwe
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              debt.personName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (debt.comment != null && debt.comment!.isNotEmpty)
                          Text(
                            debt.comment!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tr('debts.overdue'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'repay' && onRepay != null) onRepay!();
                        if (value == 'delete' && onDelete != null) onDelete!();
                      },
                      itemBuilder: (context) => [
                        if (onRepay != null && !debt.isClosed)
                          PopupMenuItem(
                            value: 'repay',
                            child: Row(
                              children: [
                                Icon(Icons.payment,
                                    size: 20, color: primaryColor),
                                const SizedBox(width: 8),
                                Text(tr('debts.repay')),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete,
                                    size: 20, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Text(tr('delete'),
                                    style: TextStyle(
                                        color: theme.colorScheme.error)),
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
                  valueColor: AlwaysStoppedAnimation(primaryColor),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .scaleX(begin: 0, end: 1, duration: 600.ms, delay: 200.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              // Суммы
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('debts.repaid'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatMoney(debt.repaidAmount.amountInCents,
                            debt.totalAmount.currencyCode),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tr('debts.total'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatMoney(debt.totalAmount.amountInCents,
                            debt.totalAmount.currencyCode),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Остаток
              const SizedBox(height: 8),
              if (debt.isClosed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        tr('debts.closed'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '${tr('debts.remaining')}: ${_formatMoney(debt.remainingAmount.amountInCents, debt.totalAmount.currencyCode)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              // Дата возврата
              if (debt.dueDate != null && !debt.isClosed) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isOverdue
                          ? Colors.orange
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tr('debts.due_date')}: ${DateFormat.yMd().format(debt.dueDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue
                            ? Colors.orange
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],

              // Кнопка погашения
              if (!debt.isClosed && onRepay != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRepay,
                    icon: const Icon(Icons.payment),
                    label: Text(tr('debts.repay')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
