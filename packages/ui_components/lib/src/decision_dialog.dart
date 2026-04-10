import 'dart:ui';

import 'package:flutter/material.dart';

/// Центрированная модалка решения: скругление 28, лёгкое стекло, без сырого M3 AlertDialog.
class DecisionDialog extends StatelessWidget {
  const DecisionDialog({
    super.key,
    required this.title,
    required this.content,
    required this.footer,
  });

  final String title;
  final Widget content;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400, maxHeight: maxH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxH - 200,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: content,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: footer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
