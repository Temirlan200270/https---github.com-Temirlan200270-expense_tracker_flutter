import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/expenses_providers.dart';
import '../widgets/category_search_field.dart';

class NewRecurringExpensePage extends ConsumerStatefulWidget {
  const NewRecurringExpensePage({
    super.key,
    this.recurringExpense,
  });

  final RecurringExpense? recurringExpense;

  @override
  ConsumerState<NewRecurringExpensePage> createState() =>
      _NewRecurringExpensePageState();
}

class _NewRecurringExpensePageState
    extends ConsumerState<NewRecurringExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late ExpenseType _type;
  late RecurrenceType _recurrenceType;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _categoryId;
  bool _isActive = true;

  bool get _isEditing => widget.recurringExpense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final recurring = widget.recurringExpense!;
      _type = recurring.type;
      _recurrenceType = recurring.recurrenceType;
      _startDate = recurring.startDate;
      _endDate = recurring.endDate;
      _categoryId = recurring.categoryId;
      _isActive = recurring.isActive;
      _nameController.text = recurring.name;
      _amountController.text = recurring.amount.amount.toString();
      _noteController.text = recurring.note ?? '';
    } else {
      _type = ExpenseType.expense;
      _recurrenceType = RecurrenceType.monthly;
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final currencyCode = ref.watch(defaultCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? tr('recurring.edit_title')
            : tr('recurring.create_title')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название подписки
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr('recurring.name'),
                hintText: tr('recurring.name_hint'),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr('recurring.name_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Тип (доход/расход)
            SegmentedButton<ExpenseType>(
              segments: [
                ButtonSegment(
                  value: ExpenseType.expense,
                  label: Text(tr('expenses.form.expense')),
                  icon: const Icon(Icons.trending_down),
                ),
                ButtonSegment(
                  value: ExpenseType.income,
                  label: Text(tr('expenses.form.income')),
                  icon: const Icon(Icons.trending_up),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 16),

            // Сумма
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr('expenses.form.amount'),
                suffixText: currencyCode,
                prefixIcon: const Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr('expenses.form.amount_required');
                }
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return tr('expenses.form.amount_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Категория
            categoriesAsync.when(
              data: (categories) => CategorySearchField(
                categories: categories,
                selectedCategoryId: _categoryId,
                onCategorySelected: (value) =>
                    setState(() => _categoryId = value),
                type: _type,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(tr('expenses.form.categories_error')),
            ),
            const SizedBox(height: 16),

            // Тип повторения
            DropdownButtonFormField<RecurrenceType>(
              initialValue: _recurrenceType,
              decoration: InputDecoration(
                labelText: tr('recurring.frequency'),
                prefixIcon: const Icon(Icons.repeat),
              ),
              items: RecurrenceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(context.locale.languageCode == 'ru'
                      ? type.displayName
                      : type.displayNameEn),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _recurrenceType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Дата начала
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('recurring.start_date')),
              subtitle: Text(DateFormat.yMMMMd(context.locale.toLanguageTag())
                  .format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: _startDate,
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
            ),
            const SizedBox(height: 8),

            // Дата окончания (опционально)
            SwitchListTile(
              title: Text(tr('recurring.has_end_date')),
              subtitle: _endDate != null
                  ? Text(DateFormat.yMMMMd(context.locale.toLanguageTag())
                      .format(_endDate!))
                  : null,
              value: _endDate != null,
              onChanged: (value) async {
                if (value) {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: _startDate,
                    lastDate: DateTime(2100),
                    initialDate:
                        _endDate ?? _startDate.add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                  }
                } else {
                  setState(() => _endDate = null);
                }
              },
            ),
            const SizedBox(height: 16),

            // Заметка
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: tr('expenses.form.note'),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Кнопка сохранения
            FilledButton.icon(
              onPressed: () => _handleSubmit(ref),
              icon: const Icon(Icons.save),
              label: Text(tr('save')),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    HapticUtils.mediumImpact();

    final currencyCode = ref.read(defaultCurrencyProvider);
    final number = double.parse(_amountController.text.replaceAll(',', '.'));
    final repo = ref.read(recurringExpensesRepositoryProvider);

    final recurring = RecurringExpense(
      id: _isEditing ? widget.recurringExpense!.id : null,
      name: _nameController.text,
      amount: Money(
          amountInCents: (number * 100).round(), currencyCode: currencyCode),
      type: _type,
      recurrenceType: _recurrenceType,
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _categoryId,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      isActive: _isActive,
    );

    try {
      await repo.upsert(recurring);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? tr('recurring.updated') : tr('recurring.created')),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('recurring.error', args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
