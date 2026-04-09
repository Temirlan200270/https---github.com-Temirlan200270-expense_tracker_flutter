import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/expenses_providers.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return PrimaryScaffold(
      title: tr('categories.title'),
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          onPressed: () => context.push('/rules'),
          tooltip: tr('rules.title'),
        ),
      ],
      fab: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      child: categoriesAsync.when(
        data: (categories) {
          final expenseCategories = categories.where((c) => c.kind.isExpense).toList();
          final incomeCategories = categories.where((c) => !c.kind.isExpense).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Категории расходов
              _CategorySection(
                title: tr('categories.expenses'),
                categories: expenseCategories,
                kind: CategoryKind.expense,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              // Категории доходов
              _CategorySection(
                title: tr('categories.incomes'),
                categories: incomeCategories,
                kind: CategoryKind.income,
                color: Colors.green,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, [Category? category]) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.title,
    required this.categories,
    required this.kind,
    required this.color,
  });

  final String title;
  final List<Category> categories;
  final CategoryKind kind;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _showCategoryDialog(context, ref, kind),
              icon: const Icon(Icons.add),
              tooltip: tr('categories.add'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (categories.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  tr('categories.empty'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          )
        else
          ...categories.map((category) => _CategoryTile(category: category)),
      ],
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, CategoryKind kind) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(initialKind: kind),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(category.id),
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
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('categories.delete.title')),
            content: Text(tr('categories.delete.message')),
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
        ) ?? false;
      },
      onDismissed: (direction) async {
        final repo = ref.read(categoriesRepositoryProvider);
        await repo.softDelete(category.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('categories.delete.success'))),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(category.colorValue),
            child: Icon(
              category.kind.isExpense ? Icons.trending_down : Icons.trending_up,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(category.name),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, ref),
          ),
          onTap: () => _showEditDialog(context, ref),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({
    this.category,
    this.initialKind,
  });

  final Category? category;
  final CategoryKind? initialKind;

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late CategoryKind _kind;
  late int _colorValue;

  static const _availableColors = [
    0xFF4CAF50, // Green
    0xFF2196F3, // Blue
    0xFF9C27B0, // Purple
    0xFFE53935, // Red
    0xFFFF9800, // Orange
    0xFF00BCD4, // Cyan
    0xFF795548, // Brown
    0xFF607D8B, // BlueGrey
    0xFFE91E63, // Pink
    0xFF3F51B5, // Indigo
    0xFF009688, // Teal
    0xFFFFEB3B, // Yellow
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _kind = widget.category?.kind ?? widget.initialKind ?? CategoryKind.expense;
    _colorValue = widget.category?.colorValue ?? _availableColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? tr('categories.edit') : tr('categories.add')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tr('categories.name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('categories.name_required');
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text(
                tr('categories.type'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<CategoryKind>(
                segments: [
                  ButtonSegment(
                    value: CategoryKind.expense,
                    label: Text(tr('expenses.form.expense')),
                    icon: const Icon(Icons.trending_down),
                  ),
                  ButtonSegment(
                    value: CategoryKind.income,
                    label: Text(tr('expenses.form.income')),
                    icon: const Icon(Icons.trending_up),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (value) => setState(() => _kind = value.first),
              ),
              const SizedBox(height: 16),
              Text(
                tr('categories.color'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = _colorValue == color;
                  return GestureDetector(
                    onTap: () => setState(() => _colorValue = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(color).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(tr('save')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(categoriesRepositoryProvider);
    final category = Category(
      id: widget.category?.id,
      name: _nameController.text.trim(),
      colorValue: _colorValue,
      kind: _kind,
      createdAt: widget.category?.createdAt,
    );

    await repo.upsert(category);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.category != null
              ? tr('categories.updated')
              : tr('categories.created')),
        ),
      );
    }
  }
}

