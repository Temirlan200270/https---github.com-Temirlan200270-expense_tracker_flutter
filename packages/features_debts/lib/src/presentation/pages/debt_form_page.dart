import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/debts_providers.dart';

/// Страница создания/редактирования долга
class DebtFormPage extends ConsumerStatefulWidget {
  const DebtFormPage({
    super.key,
    this.debtId,
  });

  final String? debtId;

  bool get isEditing => debtId != null;

  @override
  ConsumerState<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  DebtType _selectedType = DebtType.theyOwe;
  DateTime? _dueDate;
  bool _hasDueDate = false;
  bool _isLoading = false;

  Debt? _existingDebt;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadDebt();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Проверяем, передан ли тип из extra через GoRouter
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null && extra['type'] is DebtType) {
      setState(() => _selectedType = extra['type'] as DebtType);
    }
  }

  Future<void> _loadDebt() async {
    setState(() => _isLoading = true);
    try {
      final debt =
          await ref.read(debtsRepositoryProvider).getDebt(widget.debtId!);
      if (debt != null && mounted) {
        setState(() {
          _existingDebt = debt;
          _personController.text = debt.personName;
          _amountController.text =
              (debt.totalAmount.amountInCents / 100).toStringAsFixed(0);
          _commentController.text = debt.comment ?? '';
          _selectedType = debt.type;
          _dueDate = debt.dueDate;
          _hasDueDate = debt.dueDate != null;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);

    if (_isLoading) {
      return PrimaryScaffold(
        title: tr('debts.loading'),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return PrimaryScaffold(
      title: widget.isEditing ? tr('debts.edit') : tr('debts.create'),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Тип долга
            Text(
              tr('debts.type'),
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
              child: SegmentedButton<DebtType>(
                segments: [
                  ButtonSegment(
                    value: DebtType.theyOwe,
                    label: Text(tr('debts.they_owe')),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 20, color: Colors.green),
                  ),
                  ButtonSegment(
                    value: DebtType.iOwe,
                    label: Text(tr('debts.i_owe')),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.red),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() => _selectedType = selection.first);
                },
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Имя человека
            TextFormField(
              controller: _personController,
              decoration: InputDecoration(
                labelText: tr('debts.person_name'),
                hintText: tr('debts.person_name_hint'),
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
                    Icons.person_outline_rounded,
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
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr('debts.person_name_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Сумма
            TextFormField(
              controller: _amountController,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: tr('debts.amount'),
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
                  return tr('debts.amount_required');
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return tr('debts.amount_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Дата возврата
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
                  tr('debts.has_due_date'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: _dueDate != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat.yMMMMd(context.locale.toLanguageTag()).format(_dueDate!),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : null,
                value: _hasDueDate,
                onChanged: (value) {
                  setState(() {
                    _hasDueDate = value;
                    if (!value) {
                      _dueDate = null;
                    } else {
                      _dueDate ??= DateTime.now().add(const Duration(days: 30));
                    }
                  });
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            if (_hasDueDate) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final navigatorContext = context;
                      final picked = await showDatePicker(
                        context: navigatorContext,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null && mounted) {
                        setState(() => _dueDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('debts.select_date'),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _dueDate != null
                                      ? DateFormat.yMMMMd(context.locale.toLanguageTag()).format(_dueDate!)
                                      : tr('debts.select_date'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Комментарий
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: tr('debts.comment'),
                hintText: tr('debts.comment_hint'),
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
                    Icons.note_outlined,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Кнопка сохранения
            FilledButton.icon(
              onPressed: _saveDebt,
              icon: const Icon(Icons.check_rounded, size: 22),
              label: Text(
                widget.isEditing ? tr('save') : tr('debts.create'),
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

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    final defaultCurrency = ref.read(defaultCurrencyProvider);
    final amountAmount = int.parse(_amountController.text);
    final amount = Money(
      amountInCents: amountAmount * 100,
      currencyCode: defaultCurrency,
    );

    final controller = ref.read(debtsControllerProvider.notifier);

    if (widget.isEditing && _existingDebt != null) {
      await controller.updateDebt(
        _existingDebt!.copyWith(
          personName: _personController.text.trim(),
          totalAmount: amount,
          type: _selectedType,
          dueDate: _hasDueDate ? _dueDate : null,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        ),
      );
    } else {
      await controller.createDebt(
        personName: _personController.text.trim(),
        amount: amount,
        type: _selectedType,
        dueDate: _hasDueDate ? _dueDate : null,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.isEditing ? tr('debts.updated') : tr('debts.created')),
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
