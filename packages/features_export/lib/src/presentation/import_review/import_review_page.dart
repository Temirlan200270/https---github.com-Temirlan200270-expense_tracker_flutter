import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_expenses/features_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import 'import_review_controller.dart';

/// Экран подтверждения импорта: приоритетный список, категории, bulk-действия.
class ImportReviewPage extends ConsumerStatefulWidget {
  const ImportReviewPage({super.key});

  @override
  ConsumerState<ImportReviewPage> createState() => _ImportReviewPageState();
}

class _ImportReviewPageState extends ConsumerState<ImportReviewPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(importReviewControllerProvider);
    final notifier = ref.read(importReviewControllerProvider.notifier);
    final theme = Theme.of(context);
    final currency = ref.watch(defaultCurrencyProvider);

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('import.review.title'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr('import.review.empty'),
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(tr('import.close')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final selected = items.where((e) => e.isIncluded).length;
    final confidentCount = items
        .where(
          (e) =>
              e.confidence >= 0.9 &&
              e.predictedCategoryId != null &&
              e.effectiveCategoryId != null,
        )
        .length;

    final attention = <(int, PendingImportExpense)>[];
    final ready = <(int, PendingImportExpense)>[];
    for (var i = 0; i < items.length; i++) {
      final e = items[i];
      if (e.needsAttention) {
        attention.add((i, e));
      } else {
        ready.add((i, e));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('import.review.title')),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    notifier.applyDefaultInclusion();
                  },
            child: Text(tr('import.review.apply_defaults')),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: EnhancedExpenseCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr(
                        'import.review.selected_count',
                        args: [
                          selected.toString(),
                          items.length.toString(),
                        ],
                      ),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: confidentCount == 0 || _saving
                          ? null
                          : () => notifier.confirmAllConfident(),
                      child: Text(
                        tr(
                          'import.review.confirm_confident',
                          args: [confidentCount.toString()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (attention.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        tr('import.review.section_attention'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final (index, e) = attention[i];
                        return _ReviewTile(
                          index: index,
                          item: e,
                          currencyCode: currency,
                          animIndex: i,
                        );
                      },
                      childCount: attention.length,
                    ),
                  ),
                ],
                if (ready.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        tr('import.review.section_ready'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final (index, e) = ready[i];
                        return _ReviewTile(
                          index: index,
                          item: e,
                          currencyCode: currency,
                          animIndex: attention.length + i,
                        );
                      },
                      childCount: ready.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving || selected == 0 ? null : () => _save(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr('import.review.save')),
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _saving = true);
    final items = ref.read(importReviewControllerProvider);
    final toSave =
        items.where((e) => e.isIncluded).map((e) => e.toExpenseForSave()).toList();
    final repo = ref.read(expensesRepositoryProvider);
    var ok = 0;
    try {
      for (final e in toSave) {
        try {
          await repo.upsertExpense(e);
          ok++;
        } catch (_) {}
      }
      ref.read(importReviewControllerProvider.notifier).clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('import.review.success', args: [ok.toString()]),
          ),
        ),
      );
      if (context.canPop()) {
        context.pop();
      }
      if (context.mounted && context.canPop()) {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({
    required this.index,
    required this.item,
    required this.currencyCode,
    required this.animIndex,
  });

  final int index;
  final PendingImportExpense item;
  final String currencyCode;
  final int animIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(importReviewControllerProvider.notifier);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final title = sanitizeTitleForMatch(item.parsed.note ?? '');
    final displayTitle =
        title.isEmpty ? (item.parsed.note ?? '—') : title;
    final formatter = NumberFormat.currency(symbol: currencyCode);
    final amountLabel = formatter.format(item.parsed.amount.amount.abs());
    final dateLabel =
        DateFormat.yMMMd(context.locale.toLanguageTag()).format(
      item.parsed.occurredAt,
    );

    final dotColor = _confidenceColor(theme, item);
    final sameCount = notifier.countWithSameSanitizedTitle(index);

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: EnhancedExpenseCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pickCategory(
            context,
            ref,
            categoriesAsync.valueOrNull ?? [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateLabel · $amountLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (sameCount > 1) ...[
                        const SizedBox(height: 6),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            final id = await _pickCategoryId(
                              context,
                              categoriesAsync.valueOrNull ?? [],
                            );
                            if (!context.mounted || id == null || id.isEmpty) {
                              return;
                            }
                            notifier.applyCategoryToSameSanitizedTitle(
                              index,
                              id,
                            );
                          },
                          child: Text(
                            tr(
                              'import.review.apply_same_title',
                              args: [sameCount.toString()],
                            ),
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                categoriesAsync.when(
                  data: (cats) {
                    Category? cat;
                    if (item.effectiveCategoryId != null) {
                      for (final c in cats) {
                        if (c.id == item.effectiveCategoryId) {
                          cat = c;
                          break;
                        }
                      }
                    }
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: cat != null
                              ? Color(cat.colorValue)
                                  .withOpacity(0.85)
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            cat != null ? Icons.label : Icons.label_outline,
                            size: 20,
                            color: cat != null
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat?.name ?? tr('import.review.pick_category'),
                          style: theme.textTheme.labelSmall,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(Icons.error_outline),
                ),
                Checkbox(
                  value: item.isIncluded,
                  onChanged: (_) => notifier.toggleInclusion(index),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final delayMs = AppMotion.staggerInterval.inMilliseconds * animIndex;
    return Dismissible(
      key: ValueKey(
        'import-${item.parsed.id}-${item.parsed.occurredAt.toIso8601String()}',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.remove_circle_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) => notifier.removeAt(index),
      child: tile
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: delayMs),
            duration: AppMotion.standard,
            curve: AppMotion.curve,
          )
          .slideY(
            begin: 0.08,
            end: 0,
            delay: Duration(milliseconds: delayMs),
            duration: AppMotion.standard,
            curve: AppMotion.curve,
          ),
    );
  }

  Color _confidenceColor(ThemeData theme, PendingImportExpense e) {
    if (e.confidence >= 0.9) return theme.colorScheme.primary;
    if (e.confidence >= kPendingImportLowConfidence) {
      return theme.colorScheme.tertiary;
    }
    return theme.colorScheme.error;
  }

  Future<void> _pickCategory(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) async {
    final result = await _pickCategoryId(context, categories);
    if (!context.mounted || result == null) return;
    final notifier = ref.read(importReviewControllerProvider.notifier);
    if (result.isEmpty) {
      notifier.updateCategory(index, null);
    } else {
      notifier.updateCategory(index, result);
    }
  }

  /// `null` — отмена, `''` — сброс категории, иначе id.
  static Future<String?> _pickCategoryId(
    BuildContext context,
    List<Category> categories,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(tr('import.review.clear_category')),
                leading: const Icon(Icons.clear),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              const Divider(height: 1),
              ...categories.map(
                (c) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(c.colorValue),
                    radius: 16,
                  ),
                  title: Text(c.name),
                  onTap: () => Navigator.pop(ctx, c.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
