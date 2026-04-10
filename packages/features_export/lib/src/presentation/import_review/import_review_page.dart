import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:features_expenses/features_expenses.dart';

import '../../services/import_review_learning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../layout/import_layout_spacing.dart';
import '../widgets/import_surface_card.dart';
import 'import_review_controller.dart';

/// Кластер строк «внимания» по санитизированному названию.
class _AttentionCluster {
  const _AttentionCluster({
    required this.clusterKey,
    required this.label,
    required this.rows,
  });

  final String clusterKey;
  final String label;
  final List<(int, PendingImportExpense, int)> rows;
}

List<_AttentionCluster> _buildAttentionClusters(
  List<(int, PendingImportExpense)> attention,
) {
  final orderedKeys = <String>[];
  final map = <String, List<(int, PendingImportExpense)>>{};
  for (final pair in attention) {
    final sanitized = sanitizeTitleForMatch(pair.$2.parsed.note ?? '');
    final key = sanitized.isEmpty ? '__empty__' : sanitized;
    map.putIfAbsent(key, () => []).add(pair);
    if (!orderedKeys.contains(key)) {
      orderedKeys.add(key);
    }
  }

  var anim = 0;
  final out = <_AttentionCluster>[];
  for (final key in orderedKeys) {
    final pairs = map[key]!;
    final rows = <(int, PendingImportExpense, int)>[];
    for (final p in pairs) {
      rows.add((p.$1, p.$2, anim++));
    }
    final label = key == '__empty__' ? '—' : key;
    out.add(
      _AttentionCluster(
        clusterKey: key,
        label: label,
        rows: rows,
      ),
    );
  }
  return out;
}

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
      return PrimaryScaffold(
        title: tr('import.review.title'),
        child: EmptyState(
          icon: Icons.playlist_remove_rounded,
          title: tr('import.review.empty'),
          action: PrimaryActionButton(
            height: 48,
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(tr('import.close')),
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

    final attentionClusters = _buildAttentionClusters(attention);

    return PrimaryScaffold(
      title: tr('import.review.title'),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ImportLayoutSpacing.s20,
            ImportLayoutSpacing.s8,
            ImportLayoutSpacing.s20,
            ImportLayoutSpacing.s16,
          ),
          child: PrimaryActionButton(
            height: 52,
            hapticOnPress: !_saving && selected > 0,
            onPressed: _saving || selected == 0 ? null : () => _save(context),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ImportLayoutSpacing.s20,
              ImportLayoutSpacing.s8,
              ImportLayoutSpacing.s20,
              ImportLayoutSpacing.s8,
            ),
            child: EnhancedExpenseCard(
              child: Padding(
                padding: const EdgeInsets.all(ImportLayoutSpacing.s16),
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
                    SizedBox(height: ImportLayoutSpacing.s12),
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
                if (attentionClusters.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        ImportLayoutSpacing.s20,
                        ImportLayoutSpacing.s8,
                        ImportLayoutSpacing.s20,
                        ImportLayoutSpacing.s4,
                      ),
                      child: Text(
                        tr('import.review.section_attention'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  for (final cluster in attentionClusters) ...[
                    if (cluster.rows.length > 1)
                      SliverToBoxAdapter(
                        child: _AttentionClusterBar(
                          label: cluster.label,
                          count: cluster.rows.length,
                          onCategoryPicked: (categoryId) {
                            notifier.applyCategoryToSameSanitizedTitle(
                              cluster.rows.first.$1,
                              categoryId,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(tr('import.review.reinforce_hint')),
                                  duration: AppMotion.standard + AppMotion.fast,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final row = cluster.rows[i];
                          return _ReviewTile(
                            index: row.$1,
                            item: row.$2,
                            currencyCode: currency,
                            animIndex: row.$3,
                            compact: false,
                          );
                        },
                        childCount: cluster.rows.length,
                      ),
                    ),
                  ],
                ],
                if (ready.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        ImportLayoutSpacing.s20,
                        ImportLayoutSpacing.s16,
                        ImportLayoutSpacing.s20,
                        ImportLayoutSpacing.s4,
                      ),
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
                        final compact = e.confidence >= 0.85;
                        return _ReviewTile(
                          index: index,
                          item: e,
                          currencyCode: currency,
                          animIndex: attention.length + i,
                          compact: compact,
                        );
                      },
                      childCount: ready.length,
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(height: ImportLayoutSpacing.s32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _saving = true);
    final snapshot = List<PendingImportExpense>.from(
      ref.read(importReviewControllerProvider),
    );
    final toSave = snapshot
        .where((e) => e.isIncluded)
        .map((e) => e.toExpenseForSave())
        .toList();
    final skipped = snapshot.where((e) => !e.isIncluded).length;
    final corrected = snapshot
        .where(
          (e) =>
              e.isIncluded &&
              e.effectiveCategoryId != null &&
              e.effectiveCategoryId != e.predictedCategoryId,
        )
        .length;

    final repo = ref.read(expensesRepositoryProvider);
    final rulesRepo = ref.read(categoryRulesRepositoryProvider);
    final learning = ImportReviewLearningService(rulesRepo);

    var ok = 0;
    var rulesLearned = 0;
    try {
      for (final e in toSave) {
        try {
          await repo.upsertExpense(e);
          ok++;
        } catch (_) {}
      }

      try {
        rulesLearned = await learning.learnFromReviewSnapshot(snapshot);
      } catch (_) {
        rulesLearned = 0;
      }

      ref.read(importReviewControllerProvider.notifier).clear();
      if (!context.mounted) return;

      final failed = toSave.length - ok;
      var msg = failed > 0
          ? tr(
              'import.review.recap_with_errors',
              args: [
                ok.toString(),
                skipped.toString(),
                corrected.toString(),
                failed.toString(),
              ],
            )
          : tr(
              'import.review.recap',
              args: [
                ok.toString(),
                skipped.toString(),
                corrected.toString(),
              ],
            );

      if (rulesLearned > 0) {
        msg =
            '$msg\n${tr('import.review.recap_learned', args: [rulesLearned.toString()])}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: AppMotion.screen + AppMotion.standard + AppMotion.fast,
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

/// Заголовок кластера + групповое назначение категории.
class _AttentionClusterBar extends ConsumerWidget {
  const _AttentionClusterBar({
    required this.label,
    required this.count,
    required this.onCategoryPicked,
  });

  final String label;
  final int count;
  final void Function(String categoryId) onCategoryPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ImportLayoutSpacing.s20,
        ImportLayoutSpacing.s4,
        ImportLayoutSpacing.s20,
        ImportLayoutSpacing.s4,
      ),
      child: ImportSurfaceCard(
        backgroundColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ImportLayoutSpacing.s12,
            vertical: ImportLayoutSpacing.s8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.hub_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: ImportLayoutSpacing.s8),
              Expanded(
                child: Text(
                  tr(
                    'import.review.cluster_count',
                    args: [label, count.toString()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final id = await _ReviewTile.pickCategoryIdStatic(
                    context,
                    categoriesAsync.valueOrNull ?? [],
                  );
                  if (!context.mounted || id == null || id.isEmpty) return;
                  onCategoryPicked(id);
                },
                child: Text(tr('import.review.cluster_pick_category')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({
    required this.index,
    required this.item,
    required this.currencyCode,
    required this.animIndex,
    this.compact = false,
  });

  final int index;
  final PendingImportExpense item;
  final String currencyCode;
  final int animIndex;
  final bool compact;

  /// Для групповых действий снаружи.
  static Future<String?> pickCategoryIdStatic(
    BuildContext context,
    List<Category> categories,
  ) {
    return _openCategorySheet(context, categories);
  }

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

    final accentColor = ConfidencePalette.accentColor(
      theme,
      confidence: item.confidence,
    );
    final sameCount = notifier.countWithSameSanitizedTitle(index);
    final barHeight = compact ? 36.0 : 48.0;

    final Widget? belowSubtitle = (!compact && sameCount > 1)
        ? TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              final id = await _openCategorySheet(
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('import.review.reinforce_hint')),
                    duration: AppMotion.standard + AppMotion.fast,
                  ),
                );
              }
            },
            child: Text(
              tr(
                'import.review.apply_same_title',
                args: [sameCount.toString()],
              ),
              style: theme.textTheme.labelSmall,
            ),
          )
        : null;

    final tile = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ImportLayoutSpacing.s20,
        vertical: compact ? 3 : 6,
      ),
      child: EnhancedExpenseCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pickCategory(
            context,
            ref,
            categoriesAsync.valueOrNull ?? [],
          ),
          child: CompactRow(
            title: displayTitle,
            subtitle: '$dateLabel · $amountLabel',
            belowSubtitle: belowSubtitle,
            leadingAccentColor: accentColor,
            leadingAccentHeight: barHeight,
            compact: compact,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    final avR = compact ? 14.0 : 18.0;
                    final Color avatarBg = cat != null
                        ? Color(cat.colorValue).withValues(alpha: 0.85)
                        : theme.colorScheme.surfaceContainerHighest;
                    final Color avatarIconColor = cat != null
                        ? (ThemeData.estimateBrightnessForColor(avatarBg) ==
                                Brightness.dark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.onSurface)
                        : theme.colorScheme.onSurfaceVariant;
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: avR,
                          backgroundColor: avatarBg,
                          child: Icon(
                            cat != null ? Icons.label : Icons.label_outline,
                            size: compact ? 16 : 20,
                            color: avatarIconColor,
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 72,
                            child: Text(
                              cat?.name ?? tr('import.review.pick_category'),
                              style: theme.textTheme.labelSmall,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => SizedBox(
                    width: compact ? 28 : 36,
                    height: compact ? 28 : 36,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(Icons.error_outline),
                ),
                Checkbox(
                  visualDensity: compact
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  materialTapTargetSize: compact
                      ? MaterialTapTargetSize.shrinkWrap
                      : null,
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
        padding: const EdgeInsets.only(right: ImportLayoutSpacing.s24),
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

  Future<void> _pickCategory(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) async {
    final result = await _openCategorySheet(context, categories);
    if (!context.mounted || result == null) return;
    final notifier = ref.read(importReviewControllerProvider.notifier);
    if (result.isEmpty) {
      notifier.updateCategory(index, null);
    } else {
      notifier.updateCategory(index, result);
    }
  }

  static Future<String?> _openCategorySheet(
    BuildContext context,
    List<Category> categories,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final maxH = MediaQuery.sizeOf(ctx).height * 0.65;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: ImportLayoutSpacing.s16),
            children: [
              _ImportReviewSheetRow(
                leading: Icon(Icons.clear_rounded, color: cs.onSurfaceVariant),
                label: tr('import.review.clear_category'),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              ...categories.map(
                (c) => _ImportReviewSheetRow(
                  leading: CircleAvatar(
                    backgroundColor: Color(c.colorValue),
                    radius: 16,
                  ),
                  label: c.name,
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

/// Строка выбора категории без ListTile (Action Mode).
class _ImportReviewSheetRow extends StatelessWidget {
  const _ImportReviewSheetRow({
    required this.leading,
    required this.label,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ImportLayoutSpacing.s20,
            vertical: ImportLayoutSpacing.s12,
          ),
          child: Row(
            children: [
              leading,
              SizedBox(width: ImportLayoutSpacing.s16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
