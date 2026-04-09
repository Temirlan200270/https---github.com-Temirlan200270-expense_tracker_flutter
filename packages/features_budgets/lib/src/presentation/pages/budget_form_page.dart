import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/budgets_providers.dart';

/// Страница создания/редактирования бюджета
class BudgetFormPage extends ConsumerStatefulWidget {
  const BudgetFormPage({
    super.key,
    this.budgetId,
  });

  final String? budgetId;

  bool get isEditing => budgetId != null;

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  String? _selectedCategoryId;
  int _warningPercent = 80;
  bool _notificationsEnabled = true;

  Budget? _existingBudget;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadBudget();
    }
  }

  Future<void> _loadBudget() async {
    setState(() => _isLoading = true);
    try {
      final budget =
          await ref.read(budgetsRepositoryProvider).getBudget(widget.budgetId!);
      if (budget != null && mounted) {
        setState(() {
          _existingBudget = budget;
          _nameController.text = budget.name;
          _limitController.text =
              (budget.limit.amountInCents / 100).toStringAsFixed(0);
          _selectedPeriod = budget.period;
          _selectedCategoryId = budget.categoryId;
          _warningPercent = budget.warningPercent;
          _notificationsEnabled = budget.notificationsEnabled;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);

    if (_isLoading) {
      return PrimaryScaffold(
        title: tr('budget.loading'),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return PrimaryScaffold(
      title: widget.isEditing ? tr('budget.edit') : tr('budget.create'),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название бюджета
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr('budget.name'),
                hintText: tr('budget.name_hint'),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.label_outline_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr('budget.name_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Лимит
            TextFormField(
              controller: _limitController,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: tr('budget.limit_amount'),
                hintText: '50000',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                suffixText: _getCurrencySymbol(defaultCurrency),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr('budget.limit_required');
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return tr('budget.limit_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Период
            Text(
              tr('budget.period'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: SegmentedButton<BudgetPeriod>(
                segments: BudgetPeriod.values.map((period) {
                  return ButtonSegment(
                    value: period,
                    label: Text(
                      context.locale.languageCode == 'ru'
                          ? period.displayName
                          : period.displayNameEn,
                    ),
                  );
                }).toList(),
                selected: {_selectedPeriod},
                onSelectionChanged: (selection) {
                  setState(() => _selectedPeriod = selection.first);
                },
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Категория (опционально)
            Text(
              tr('budget.category_optional'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(tr('error_loading_categories')),
              data: (categories) {
                // Фильтруем только категории расходов
                final expenseCategories = categories
                    .where((c) => c.kind == CategoryKind.expense)
                    .toList();

                return DropdownButtonFormField<String?>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    hintText: tr('budget.all_categories'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Row(
                        children: [
                          const Icon(Icons.all_inclusive, size: 20),
                          const SizedBox(width: 8),
                          Text(tr('budget.all_categories')),
                        ],
                      ),
                    ),
                    ...expenseCategories.map((category) {
                      return DropdownMenuItem<String?>(
                        value: category.id,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(category.colorValue),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Порог предупреждения
            Text(
              tr('budget.warning_threshold'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _warningPercent.toDouble(),
                          min: 50,
                          max: 100,
                          divisions: 10,
                          label: '$_warningPercent%',
                          onChanged: (value) {
                            setState(() => _warningPercent = value.round());
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$_warningPercent%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              tr('budget.warning_threshold_hint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Уведомления
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                title: Text(
                  tr('budget.notifications'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr('budget.notifications_hint'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 32),

            // Кнопка сохранения
            FilledButton.icon(
              onPressed: _saveBudget,
              icon: const Icon(Icons.check_rounded, size: 22),
              label: Text(
                widget.isEditing ? tr('save') : tr('budget.create'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final defaultCurrency = ref.read(defaultCurrencyProvider);
    final limitAmount = int.parse(_limitController.text);
    final controller = ref.read(budgetsControllerProvider.notifier);

    if (widget.isEditing && _existingBudget != null) {
      await controller.updateBudget(
        _existingBudget!.copyWith(
          name: _nameController.text.trim(),
          limit: Money(
            amountInCents: limitAmount * 100,
            currencyCode: defaultCurrency,
          ),
          period: _selectedPeriod,
          categoryId: _selectedCategoryId,
          warningPercent: _warningPercent,
          notificationsEnabled: _notificationsEnabled,
        ),
      );
    } else {
      await controller.createBudget(
        name: _nameController.text.trim(),
        limitInCents: limitAmount * 100,
        currencyCode: defaultCurrency,
        period: _selectedPeriod,
        categoryId: _selectedCategoryId,
        warningPercent: _warningPercent,
        notificationsEnabled: _notificationsEnabled,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.isEditing ? tr('budget.updated') : tr('budget.created')),
        ),
      );
      context.pop();
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
