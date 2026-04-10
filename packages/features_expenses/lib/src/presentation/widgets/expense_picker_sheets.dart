import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

/// Выбор категории расхода из bottom sheet (вместо DropdownButtonFormField).
Future<String?> showExpenseCategoryPickerSheet({
  required BuildContext context,
  required List<Category> expenseCategories,
  String? selectedId,
}) {
  return showSssModalSheet<String>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SssSheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('rules.category'),
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: expenseCategories.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
                itemBuilder: (context, index) {
                  final c = expenseCategories[index];
                  final selected = c.id == selectedId;
                  return Material(
                    color: cs.surface.withValues(alpha: 0),
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, c.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        child: CompactRow(
                          title: c.name,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(c.colorValue),
                            child: Icon(
                              Icons.category_rounded,
                              size: 18,
                              color: ThemeData.estimateBrightnessForColor(
                                        Color(c.colorValue)) ==
                                    Brightness.dark
                                  ? cs.surface
                                  : cs.onSurface,
                            ),
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: cs.primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Выбор периода повторения (вместо DropdownButtonFormField).
Future<RecurrenceType?> showRecurrenceTypePickerSheet({
  required BuildContext context,
  required RecurrenceType selected,
}) {
  return showSssModalSheet<RecurrenceType>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SssSheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('recurring.frequency'),
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            ...RecurrenceType.values.map((type) {
              final label = context.locale.languageCode == 'ru'
                  ? type.displayName
                  : type.displayNameEn;
              final isSel = type == selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: cs.surface.withValues(alpha: 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(ctx, type),
                    child: CompactRow(
                      title: label,
                      leading: Icon(
                        isSel
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSel ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}
