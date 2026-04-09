import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../providers/expenses_providers.dart';
import 'package:data_core/data_core.dart';

class ExpenseFiltersSheet extends ConsumerStatefulWidget {
  const ExpenseFiltersSheet({super.key});

  @override
  ConsumerState<ExpenseFiltersSheet> createState() =>
      _ExpenseFiltersSheetState();
}

class _ExpenseFiltersSheetState extends ConsumerState<ExpenseFiltersSheet> {
  DateTime? _fromDate;
  DateTime? _toDate;
  ExpenseType? _selectedType;
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentFilter = ref.read(expenseFilterProvider);
      setState(() {
        _fromDate = currentFilter.from;
        _toDate = currentFilter.to;
        _selectedType = currentFilter.type;
        _selectedCategories = List.from(currentFilter.categoryIds);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final currentFilter = ref.watch(expenseFilterProvider);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('filters.title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_hasActiveFilters(currentFilter))
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(tr('filters.clear')),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _DateRangeFilter(
              fromDate: _fromDate,
              toDate: _toDate,
              onFromChanged: (date) => setState(() => _fromDate = date),
              onToChanged: (date) => setState(() => _toDate = date),
            ),
            const SizedBox(height: 16),
            _TypeFilter(
              selectedType: _selectedType,
              onTypeChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) => _CategoryFilter(
                categories: categories,
                selectedIds: _selectedCategories,
                onSelectionChanged: (ids) =>
                    setState(() => _selectedCategories = ids),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _applyFilters(),
              child: Text(tr('filters.apply')),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters(ExpenseFilter filter) {
    return filter.from != null ||
        filter.to != null ||
        filter.type != null ||
        filter.categoryIds.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedType = null;
      _selectedCategories = [];
    });
    _applyFilters();
  }

  void _applyFilters() {
    final filter = ExpenseFilter(
      from: _fromDate,
      to: _toDate,
      type: _selectedType,
      categoryIds: _selectedCategories,
    );
    ref.read(expenseFilterProvider.notifier).state = filter;
    Navigator.of(context).pop();
  }
}

class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter({
    required this.fromDate,
    required this.toDate,
    required this.onFromChanged,
    required this.onToChanged,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('filters.date_range'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  fromDate != null
                      ? DateFormat.yMd(context.locale.toLanguageTag())
                          .format(fromDate!)
                      : tr('filters.from_date'),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fromDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: toDate ?? DateTime.now(),
                  );
                  if (picked != null) {
                    onFromChanged(picked);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  toDate != null
                      ? DateFormat.yMd(context.locale.toLanguageTag())
                          .format(toDate!)
                      : tr('filters.to_date'),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: toDate ?? DateTime.now(),
                    firstDate: fromDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    onToChanged(picked);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({
    required this.selectedType,
    required this.onTypeChanged,
  });

  final ExpenseType? selectedType;
  final ValueChanged<ExpenseType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('filters.type'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ExpenseType?>(
          segments: [
            ButtonSegment(
              value: null,
              label: Text(tr('filters.all')),
            ),
            ButtonSegment(
              value: ExpenseType.income,
              label: Text(tr('expenses.form.income')),
              icon: const Icon(Icons.trending_up),
            ),
            ButtonSegment(
              value: ExpenseType.expense,
              label: Text(tr('expenses.form.expense')),
              icon: const Icon(Icons.trending_down),
            ),
          ],
          selected: {selectedType},
          onSelectionChanged: (value) => onTypeChanged(value.firstOrNull),
        ),
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  final List<Category> categories;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('filters.categories'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = selectedIds.contains(category.id);
            return FilterChip(
              label: Text(category.name),
              selected: isSelected,
              avatar: CircleAvatar(
                backgroundColor: Color(category.colorValue),
                radius: 8,
              ),
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedIds);
                if (selected) {
                  newSelection.add(category.id);
                } else {
                  newSelection.remove(category.id);
                }
                onSelectionChanged(newSelection);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
