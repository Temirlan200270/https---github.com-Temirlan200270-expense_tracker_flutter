import 'package:flutter/material.dart';

/// Элемент списка выбора: значение + произвольный [title] (текст или составной Row).
@immutable
class SelectionItem<T> {
  const SelectionItem({
    required this.value,
    required this.title,
  });

  final T value;
  final Widget title;
}

/// Список вариантов с немедленным [Navigator.pop] по тапу (без устаревшего [RadioListTile] API).
Future<T?> showSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required T current,
  required List<SelectionItem<T>> items,
}) {
  return showDialog<T>(
    context: context,
    builder: (BuildContext dialogContext) => _SelectionListDialog<T>(
      title: title,
      current: current,
      items: items,
    ),
  );
}

class _SelectionListDialog<T> extends StatelessWidget {
  const _SelectionListDialog({
    required this.title,
    required this.current,
    required this.items,
  });

  final String title;
  final T current;
  final List<SelectionItem<T>> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((SelectionItem<T> item) {
            final bool isSelected = item.value == current;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: isSelected
                    ? cs.primaryContainer.withValues(alpha: 0.35)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).pop(item.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 22,
                          color: isSelected ? cs.primary : cs.outlineVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: item.title),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
