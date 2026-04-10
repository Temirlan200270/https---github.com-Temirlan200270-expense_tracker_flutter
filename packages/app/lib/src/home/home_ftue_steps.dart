import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ui_components/ui_components.dart';

import 'home_layout_shell.dart';

/// FTUE: три шага onboarding (заполняет мёртвое пространство пустого экрана).
class HomeFtueSteps extends StatelessWidget {
  const HomeFtueSteps({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget step({
      required String text,
      required IconData icon,
      int staggerIndex = 0,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: HomeLayoutSpacing.s12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 18),
            ),
            SizedBox(width: HomeLayoutSpacing.s12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  height: 1.3,
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
        step(
          icon: Icons.edit_note_rounded,
          text: tr('home.ftue.step1'),
          staggerIndex: 0,
        ),
        step(
          icon: Icons.insights_rounded,
          text: tr('home.ftue.step2'),
          staggerIndex: 1,
        ),
        step(
          icon: Icons.auto_awesome_rounded,
          text: tr('home.ftue.step3'),
          staggerIndex: 2,
        ),
      ],
    );
  }
}
