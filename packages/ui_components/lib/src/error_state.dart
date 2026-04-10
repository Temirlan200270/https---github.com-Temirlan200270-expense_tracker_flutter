import 'package:flutter/material.dart';

import 'theme/visual_tokens.dart';

/// Явный fallback для AsyncValue.error (без сырого Exception в интерфейсе).
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });

  final String title;
  final String? message;
  final Widget? action;

  /// Встраивание в форму: меньше отступы и иконка.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconSize = compact ? 40.0 : 56.0;
    final outerPadding = compact ? SdsSpacing.md : SdsSpacing.xxl;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: iconSize,
          color: cs.error,
        ),
        SizedBox(height: compact ? SdsSpacing.sm : SdsSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          SizedBox(height: compact ? SdsSpacing.xxs : SdsSpacing.xs),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
        if (action != null) ...[
          SizedBox(height: compact ? SdsSpacing.md : SdsSpacing.xl),
          action!,
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: EdgeInsets.all(outerPadding),
        child: content,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: SdsLayout.emptyStateMaxWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(outerPadding),
          child: content,
        ),
      ),
    );
  }
}
