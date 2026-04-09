import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/category_rules_providers.dart';
import '../../providers/expenses_providers.dart';

/// Страница списка правил категоризации
class CategoryRulesPage extends ConsumerWidget {
  const CategoryRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(categoryRulesStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('rules.title')),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(tr('error_occurred')),
              TextButton(
                onPressed: () => ref.invalidate(categoryRulesStreamProvider),
                child: Text(tr('retry')),
              ),
            ],
          ),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyState(
              icon: Icons.auto_awesome,
              title: tr('rules.empty_title'),
              message: tr('rules.empty_message'),
              action: FilledButton.icon(
                onPressed: () => _showRuleDialog(context, ref, null),
                icon: const Icon(Icons.add),
                label: Text(tr('rules.create')),
              ),
            );
          }

          return categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) {
              final categoryMap = {for (var c in categories) c.id: c};

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoryRulesStreamProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: rules.length,
                  itemBuilder: (context, index) {
                    final rule = rules[index];
                    final category = categoryMap[rule.categoryId];

                    return _RuleListTile(
                      rule: rule,
                      category: category,
                      onEdit: () => _showRuleDialog(context, ref, rule),
                      onDelete: () => _confirmDelete(context, ref, rule),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRuleDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(tr('rules.add')),
      ),
    );
  }

  void _showRuleDialog(
      BuildContext context, WidgetRef ref, CategoryRule? rule) {
    showDialog(
      context: context,
      builder: (context) => _RuleFormDialog(rule: rule),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, CategoryRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('rules.delete_title')),
        content: Text(tr('rules.delete_message', args: [rule.keyword])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(categoryRulesControllerProvider.notifier)
          .deleteRule(rule.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('rules.deleted'))),
        );
      }
    }
  }
}

class _RuleListTile extends StatelessWidget {
  const _RuleListTile({
    required this.rule,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryRule rule;
  final Category? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: category != null
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(category!.colorValue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.category, color: Colors.white, size: 20),
              )
            : CircleAvatar(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.help_outline),
              ),
        title: Text(
          rule.keyword,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category?.name ?? 'Категория удалена'),
            if (rule.matchCount > 0)
              Text(
                tr('rules.match_count', args: [rule.matchCount.toString()]),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
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
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text(tr('delete'),
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

/// Диалог создания/редактирования правила
class _RuleFormDialog extends ConsumerStatefulWidget {
  const _RuleFormDialog({this.rule});

  final CategoryRule? rule;

  bool get isEditing => rule != null;

  @override
  ConsumerState<_RuleFormDialog> createState() => _RuleFormDialogState();
}

class _RuleFormDialogState extends ConsumerState<_RuleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keywordController = TextEditingController();
  String? _selectedCategoryId;
  int _priority = 0;
  bool _caseSensitive = false;

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      _keywordController.text = widget.rule!.keyword;
      _selectedCategoryId = widget.rule!.categoryId;
      _priority = widget.rule!.priority;
      _caseSensitive = widget.rule!.caseSensitive;
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return AlertDialog(
      title: Text(widget.isEditing ? tr('rules.edit') : tr('rules.create')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _keywordController,
                decoration: InputDecoration(
                  labelText: tr('rules.keyword'),
                  hintText: tr('rules.keyword_hint'),
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('rules.keyword_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(tr('error_loading_categories')),
                data: (categories) {
                  final expenseCategories = categories
                      .where((c) => c.kind == CategoryKind.expense)
                      .toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: tr('rules.category'),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: expenseCategories.map((category) {
                      return DropdownMenuItem(
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
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return tr('rules.category_required');
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(tr('rules.priority')),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: _priority.toString(),
                      decoration: const InputDecoration(
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _priority = int.tryParse(value) ?? 0;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(tr('rules.case_sensitive')),
                value: _caseSensitive,
                onChanged: (value) {
                  setState(() => _caseSensitive = value);
                },
                contentPadding: EdgeInsets.zero,
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

    final controller = ref.read(categoryRulesControllerProvider.notifier);

    if (widget.isEditing) {
      await controller.updateRule(
        widget.rule!.copyWith(
          keyword: _keywordController.text.trim(),
          categoryId: _selectedCategoryId!,
          priority: _priority,
          caseSensitive: _caseSensitive,
        ),
      );
    } else {
      await controller.createRule(
        keyword: _keywordController.text.trim(),
        categoryId: _selectedCategoryId!,
        priority: _priority,
        caseSensitive: _caseSensitive,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.isEditing ? tr('rules.updated') : tr('rules.created')),
        ),
      );
    }
  }
}

/// Диалог "Запомнить выбор" - показывается когда пользователь меняет категорию
class RememberChoiceDialog extends StatelessWidget {
  const RememberChoiceDialog({
    super.key,
    required this.keyword,
    required this.categoryName,
  });

  final String keyword;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('rules.remember_choice')),
      content: Text(tr('rules.remember_choice_hint', args: [keyword])),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(tr('save')),
        ),
      ],
    );
  }
}
