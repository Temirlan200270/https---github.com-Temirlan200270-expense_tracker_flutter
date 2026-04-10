import 'package:flutter/material.dart';

/// Ручка для нижних модалок SSS.
class SssSheetDragHandle extends StatelessWidget {
  const SssSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      decoration: BoxDecoration(
        color: cs.outlineVariant.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Оболочка bottom sheet: скругление 24, Surface 1.
class SssSheetShell extends StatelessWidget {
  const SssSheetShell({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: cs.surfaceContainerHigh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SssSheetDragHandle(),
            Padding(
              padding: padding ?? const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Единая точка входа для SSS bottom sheet (учёт клавиатуры).
Future<T?> showSssModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: builder(ctx),
      );
    },
  );
}
