import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/category_rules_providers.dart';
import '../../providers/expenses_providers.dart';
import '../widgets/expense_picker_sheets.dart';

/// Страница списка правил категоризации
class CategoryRulesPage extends ConsumerWidget {
  const CategoryRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(categoryRulesStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return PrimaryScaffold(
      title: tr('rules.title'),
      fab: FloatingActionButton.extended(
        onPressed: () => _showRuleDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(tr('rules.add')),
      ),
      child: rulesAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          title: tr('error_state.title'),
          message: tr('error_state.message'),
          action: PrimaryActionButton(
            onPressed: () => ref.invalidate(categoryRulesStreamProvider),
            child: Text(tr('retry')),
          ),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyState(
              icon: Icons.auto_awesome,
              title: tr('rules.empty_title'),
              message: tr('rules.empty_message'),
              action: PrimaryActionButton(
                onPressed: () => _showRuleDialog(context, ref, null),
                icon: const Icon(Icons.add_rounded),
                child: Text(tr('rules.create')),
              ),
            );
          }

          return categoriesAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ErrorState(
              title: tr('error_state.title'),
              message: tr('error_state.message'),
              action: PrimaryActionButton(
                onPressed: () => ref.invalidate(categoriesStreamProvider),
                child: Text(tr('retry')),
              ),
            ),
            data: (categories) {
              final categoryMap = {for (var c in categories) c.id: c};

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoryRulesStreamProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: rules.length,
                  itemBuilder: (context, index) {
                    final rule = rules[index];
                    final category = categoryMap[rule.categoryId];

                    return _RuleCompactRow(
                      index: index,
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
    final confirmed = await showConfirmActionSheet(
      context: context,
      title: tr('rules.delete_title'),
      message: tr('rules.delete_message', args: [rule.keyword]),
      cancelLabel: tr('cancel'),
      confirmLabel: tr('delete'),
      isDestructive: true,
    );

    if (confirmed) {
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

class _RuleCompactRow extends StatelessWidget {
  const _RuleCompactRow({
    required this.index,
    required this.rule,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final CategoryRule rule;
  final Category? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget? belowSubtitle;
    if (rule.matchCount > 0) {
      belowSubtitle = Text(
        tr('rules.match_count', args: [rule.matchCount.toString()]),
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    Widget leading;
    if (category != null) {
      final bg = Color(category!.colorValue);
      final iconFg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
          ? cs.surface
          : cs.onSurface;
      leading = CircleAvatar(
        radius: 22,
        backgroundColor: bg,
        child: Icon(Icons.category_rounded, color: iconFg, size: 20),
      );
    } else {
      leading = CircleAvatar(
        radius: 22,
        backgroundColor: cs.surfaceContainerHighest,
        child: Icon(Icons.help_outline_rounded, color: cs.onSurfaceVariant),
      );
    }

    final rowDelay = AppMotion.staggerInterval * index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        child: Material(
          color: cs.surface.withValues(alpha: 0),
          child: InkWell(
            onTap: onEdit,
            child: CompactRow(
              title: rule.keyword,
              subtitle: category?.name ?? tr('rules.category_missing'),
              belowSubtitle: belowSubtitle,
              leading: leading,
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: cs.onSurfaceVariant),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(tr('edit')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20, color: cs.error),
                        const SizedBox(width: 8),
                        Text(
                          tr('delete'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: AppMotion.standard,
          delay: rowDelay,
          curve: AppMotion.curve,
        )
        .slideY(
          begin: 0.06,
          duration: AppMotion.standard,
          delay: rowDelay,
          curve: AppMotion.curve,
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
  final _categoryFieldKey = GlobalKey<FormFieldState<String>>();
  final _keywordController = TextEditingController();
  int _priority = 0;
  bool _caseSensitive = false;

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      _keywordController.text = widget.rule!.keyword;
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

    return DecisionDialog(
      title: widget.isEditing ? tr('rules.edit') : tr('rules.create'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _keywordController,
              decoration: InputDecoration(
                labelText: tr('rules.keyword'),
                hintText: tr('rules.keyword_hint'),
                prefixIcon: const Icon(Icons.text_fields_rounded),
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
              skipLoadingOnReload: true,
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => ErrorState(
                compact: true,
                title: tr('expenses.form.categories_error'),
                message: tr('error_state.message'),
                action: PrimaryActionButton(
                  height: 52,
                  onPressed: () =>
                      ref.invalidate(categoriesStreamProvider),
                  child: Text(tr('retry')),
                ),
              ),
              data: (categories) {
                final expenseCategories = categories
                    .where((c) => c.kind == CategoryKind.expense)
                    .toList();

                return FormField<String>(
                  key: _categoryFieldKey,
                  initialValue: widget.rule?.categoryId,
                  validator: (value) {
                    if (value == null) {
                      return tr('rules.category_required');
                    }
                    return null;
                  },
                  builder: (fieldState) {
                    Category? selectedCat;
                    final id = fieldState.value;
                    if (id != null) {
                      for (final c in expenseCategories) {
                        if (c.id == id) {
                          selectedCat = c;
                          break;
                        }
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SettingsTile(
                          icon: Icons.category_rounded,
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: tr('rules.category'),
                          subtitle: selectedCat?.name ?? tr('common.tap_to_select'),
                          onTap: () async {
                            final picked = await showExpenseCategoryPickerSheet(
                              context: context,
                              expenseCategories: expenseCategories,
                              selectedId: fieldState.value,
                            );
                            if (picked != null) {
                              fieldState.didChange(picked);
                            }
                          },
                          animationIndex: 0,
                        ),
                        if (fieldState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 6),
                            child: Text(
                              fieldState.errorText!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                      ],
                    );
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
            SettingsTile(
              icon: Icons.sort_by_alpha_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: tr('rules.case_sensitive'),
              onTap: () => setState(() => _caseSensitive = !_caseSensitive),
              trailing: Switch.adaptive(
                value: _caseSensitive,
                onChanged: (value) => setState(() => _caseSensitive = value),
              ),
              animationIndex: 1,
            ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: SecondaryActionButton(
              height: 48,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('cancel')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryActionButton(
              height: 48,
              onPressed: _save,
              child: Text(tr('save')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cf = _categoryFieldKey.currentState;
    if (cf == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('expenses.form.categories_error'))),
        );
      }
      return;
    }
    if (!cf.validate() || cf.value == null) return;
    final categoryId = cf.value!;

    final controller = ref.read(categoryRulesControllerProvider.notifier);

    if (widget.isEditing) {
      await controller.updateRule(
        widget.rule!.copyWith(
          keyword: _keywordController.text.trim(),
          categoryId: categoryId,
          priority: _priority,
          caseSensitive: _caseSensitive,
        ),
      );
    } else {
      await controller.createRule(
        keyword: _keywordController.text.trim(),
        categoryId: categoryId,
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
    return DecisionDialog(
      title: tr('rules.remember_choice'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('rules.remember_choice_hint', args: [keyword]),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            categoryName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: SecondaryActionButton(
              height: 48,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr('cancel')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryActionButton(
              height: 48,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(tr('save')),
            ),
          ),
        ],
      ),
    );
  }
}
