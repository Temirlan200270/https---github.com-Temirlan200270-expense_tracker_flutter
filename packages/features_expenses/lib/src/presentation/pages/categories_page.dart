import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          icon: const Icon(Icons.auto_awesome_rounded),
          onPressed: () => context.push('/rules'),
          tooltip: tr('rules.title'),
        ),
      ],
      fab: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      child: categoriesAsync.when(
        data: (categories) {
          final expenseCategories = categories.where((c) => c.kind.isExpense).toList();
          final incomeCategories = categories.where((c) => !c.kind.isExpense).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              FormLayoutSpacing.s20,
              FormLayoutSpacing.s16,
              FormLayoutSpacing.s20,
              FormLayoutSpacing.s24,
            ),
            children: [
              _CategorySection(
                title: tr('categories.expenses'),
                categories: expenseCategories,
                kind: CategoryKind.expense,
                sectionIndex: 0,
              ),
              const SizedBox(height: 20),
              _CategorySection(
                title: tr('categories.incomes'),
                categories: incomeCategories,
                kind: CategoryKind.income,
                sectionIndex: 1,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          title: tr('error_state.title'),
          message: tr('error_state.message'),
          action: PrimaryActionButton(
            onPressed: () => ref.invalidate(categoriesStreamProvider),
            child: Text(tr('retry')),
          ),
        ),
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
    required this.sectionIndex,
  });

  final String title;
  final List<Category> categories;
  final CategoryKind kind;
  final int sectionIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionDelay = AppMotion.staggerInterval * sectionIndex * 3;
    final riskLevel = kind.isExpense ? RiskLevel.danger : RiskLevel.safe;
    final riskLabel =
        kind.isExpense ? tr('expenses.form.expense') : tr('expenses.form.income');

    final header = SectionHeader(
      title: title,
      padding: EdgeInsets.fromLTRB(0, sectionIndex == 0 ? 0 : 8, 0, 12),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RiskBadge(level: riskLevel, label: riskLabel),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showCategoryDialog(context, ref, kind),
            icon: const Icon(Icons.add_rounded),
            tooltip: tr('categories.add'),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: AppMotion.standard,
          delay: sectionDelay,
          curve: AppMotion.curve,
        )
        .slideY(
          begin: 0.08,
          duration: AppMotion.standard,
          delay: sectionDelay,
          curve: AppMotion.curve,
        );

    final surfaceChild = categories.isEmpty
        ? _SectionEmptyBody(message: tr('categories.empty'))
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0) _CategoryRowDivider(),
                _CategoryCompactRow(
                  category: categories[i],
                  rowIndex: i,
                  staggerBase: sectionDelay + AppMotion.staggerInterval * 2,
                ),
              ],
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SurfaceCard(child: surfaceChild)
            .animate()
            .fadeIn(
              duration: AppMotion.standard,
              delay: sectionDelay + AppMotion.staggerInterval,
              curve: AppMotion.curve,
            )
            .slideY(
              begin: 0.06,
              duration: AppMotion.standard,
              delay: sectionDelay + AppMotion.staggerInterval,
              curve: AppMotion.curve,
            ),
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

class _SectionEmptyBody extends StatelessWidget {
  const _SectionEmptyBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.layers_outlined,
            size: 40,
            color: cs.onSurfaceVariant.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 12,
      endIndent: 12,
      color: cs.outlineVariant.withValues(alpha: 0.45),
    );
  }
}

class _CategoryCompactRow extends ConsumerWidget {
  const _CategoryCompactRow({
    required this.category,
    required this.rowIndex,
    required this.staggerBase,
  });

  final Category category;
  final int rowIndex;
  final Duration staggerBase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final avatarBg = Color(category.colorValue);
    final iconOnAvatar = ThemeData.estimateBrightnessForColor(avatarBg) == Brightness.dark
        ? cs.surface
        : cs.onSurface;

    final row = Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: () => _showEditDialog(context, ref),
        child: CompactRow(
          title: category.name,
          subtitle: tr('categories.item_subtitle'),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: avatarBg,
            child: Icon(
              category.kind.isExpense ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              color: iconOnAvatar,
              size: 20,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: cs.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            onSelected: (value) async {
              if (value == 'edit') {
                _showEditDialog(context, ref);
              } else if (value == 'delete') {
                await _deleteWithUndo(context, ref, category);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(tr('categories.edit')),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(tr('delete')),
              ),
            ],
          ),
        ),
      ),
    );

    final rowDelay = staggerBase + AppMotion.staggerInterval * rowIndex;
    return row
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

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
  }

  Future<void> _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final repo = ref.read(categoriesRepositoryProvider);
    await repo.softDelete(category.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('categories.delete.success')),
        action: SnackBarAction(
          label: tr('expenses.delete.undo'),
          onPressed: () async {
            await repo.upsert(
              category.copyWith(
                isDeleted: false,
                deletedAt: null,
              ),
            );
          },
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _kind = widget.category?.kind ?? widget.initialKind ?? CategoryKind.expense;
    _colorValue = widget.category?.colorValue ?? CategoryPalette.values.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final cs = Theme.of(context).colorScheme;

    return DecisionDialog(
      title: isEditing ? tr('categories.edit') : tr('categories.add'),
      content: Form(
        key: _formKey,
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
                  icon: const Icon(Icons.trending_down_rounded),
                ),
                ButtonSegment(
                  value: CategoryKind.income,
                  label: Text(tr('expenses.form.income')),
                  icon: const Icon(Icons.trending_up_rounded),
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
              children: CategoryPalette.values.map((color) {
                final isSelected = _colorValue == color;
                final swatch = Color(color);
                final checkColor = ThemeData.estimateBrightnessForColor(swatch) == Brightness.dark
                    ? cs.surface
                    : cs.onSurface;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: cs.primary, width: 3) : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: swatch.withValues(alpha: 0.45),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: checkColor,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
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
          content: Text(
            widget.category != null ? tr('categories.updated') : tr('categories.created'),
          ),
        ),
      );
    }
  }
}
