import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ui_components/ui_components.dart';

import 'home_ftue_state.dart';
import 'home_layout_shell.dart';

/// FTUE: три шага onboarding с визуальной прогрессией.
///
/// Каждый шаг показывает статус: completed / active / pending,
/// на основании текущего [FtueStep].
class HomeFtueSteps extends StatelessWidget {
  const HomeFtueSteps({super.key, required this.currentStep});

  final FtueStep currentStep;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('home.ftue.title'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        SizedBox(height: HomeLayoutSpacing.s16),
        _FtueStepRow(
          icon: Icons.edit_note_rounded,
          text: tr('home.ftue.step1'),
          status: _statusFor(FtueStep.welcome),
          staggerIndex: 0,
        ),
        _FtueStepRow(
          icon: Icons.insights_rounded,
          text: tr('home.ftue.step2'),
          status: _statusFor(FtueStep.firstExpense),
          staggerIndex: 1,
        ),
        _FtueStepRow(
          icon: Icons.auto_awesome_rounded,
          text: tr('home.ftue.step3'),
          status: _statusFor(FtueStep.insightSeen),
          staggerIndex: 2,
        ),
      ],
    );
  }

  _StepStatus _statusFor(FtueStep stepTarget) {
    if (currentStep.index > stepTarget.index) return _StepStatus.completed;
    if (currentStep == stepTarget) return _StepStatus.active;
    return _StepStatus.pending;
  }
}

enum _StepStatus { completed, active, pending }

class _FtueStepRow extends StatelessWidget {
  const _FtueStepRow({
    required this.icon,
    required this.text,
    required this.status,
    required this.staggerIndex,
  });

  final IconData icon;
  final String text;
  final _StepStatus status;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final Color bgColor;
    final Color iconColor;
    final double textAlpha;
    final IconData resolvedIcon;

    switch (status) {
      case _StepStatus.completed:
        bgColor = cs.primary.withValues(alpha: 0.14);
        iconColor = cs.primary;
        textAlpha = 0.55;
        resolvedIcon = Icons.check_rounded;
      case _StepStatus.active:
        bgColor = cs.primaryContainer.withValues(alpha: 0.7);
        iconColor = cs.primary;
        textAlpha = 0.88;
        resolvedIcon = icon;
      case _StepStatus.pending:
        bgColor = cs.surfaceContainerHighest.withValues(alpha: 0.4);
        iconColor = cs.onSurface.withValues(alpha: 0.35);
        textAlpha = 0.45;
        resolvedIcon = icon;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: HomeLayoutSpacing.s12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(resolvedIcon, color: iconColor, size: 18),
          ),
          SizedBox(width: HomeLayoutSpacing.s12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: textAlpha),
                height: 1.3,
                decoration: status == _StepStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: AppMotion.standard,
          delay: Duration(milliseconds: 120 + 60 * staggerIndex),
          curve: AppMotion.curve,
        )
        .slideX(
          begin: 0.04,
          end: 0,
          duration: AppMotion.standard,
          delay: Duration(milliseconds: 120 + 60 * staggerIndex),
          curve: AppMotion.curve,
        );
  }
}
