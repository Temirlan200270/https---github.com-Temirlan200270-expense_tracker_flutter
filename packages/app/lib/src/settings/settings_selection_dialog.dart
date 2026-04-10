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

/// Радио-список с немедленным [Navigator.pop] при смене значения.
Future<T?> showSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required T current,
  required List<SelectionItem<T>> items,
}) {
  return showDialog<T>(
    context: context,
    builder: (BuildContext dialogContext) => _RadioSelectionDialog<T>(
      title: title,
      current: current,
      items: items,
    ),
  );
}

class _RadioSelectionDialog<T> extends StatefulWidget {
  const _RadioSelectionDialog({
    required this.title,
    required this.current,
    required this.items,
  });

  final String title;
  final T current;
  final List<SelectionItem<T>> items;

  @override
  State<_RadioSelectionDialog<T>> createState() =>
      _RadioSelectionDialogState<T>();
}

class _RadioSelectionDialogState<T> extends State<_RadioSelectionDialog<T>> {
  late T _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.items.map((SelectionItem<T> item) {
            return RadioListTile<T>(
              value: item.value,
              groupValue: _selected,
              onChanged: (T? value) {
                if (value == null) return;
                setState(() => _selected = value);
                Navigator.of(context).pop(value);
              },
              title: item.title,
            );
          }).toList(),
        ),
      ),
    );
  }
}
