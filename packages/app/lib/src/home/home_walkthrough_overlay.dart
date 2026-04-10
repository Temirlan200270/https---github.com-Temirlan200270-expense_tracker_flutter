import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'home_layout_shell.dart';

/// Полноэкранный затемнитель + карточка с шагами тура по главной (после слайдов онбординга).
class HomeWalkthroughOverlay extends StatefulWidget {
  const HomeWalkthroughOverlay({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  State<HomeWalkthroughOverlay> createState() => _HomeWalkthroughOverlayState();
}

class _HomeWalkthroughOverlayState extends State<HomeWalkthroughOverlay> {
  static const int _stepCount = 5;
  int _step = 0;

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      widget.onDismiss();
    }
  }

  void _skip() {
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final titleKey = 'home.walkthrough.step${_step + 1}_title';
    final bodyKey = 'home.walkthrough.step${_step + 1}_body';
    final isLast = _step == _stepCount - 1;

    return Positioned.fill(
      child: Material(
        color: cs.scrim.withValues(alpha: 0.52),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: const SizedBox.expand(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  HomeLayoutSpacing.s20,
                  0,
                  HomeLayoutSpacing.s20,
                  HomeLayoutSpacing.s20,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: List.generate(
                            _stepCount,
                            (i) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: i <= _step
                                        ? cs.primary
                                        : cs.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(titleKey),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(bodyKey),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _skip,
                              child: Text(tr('home.walkthrough.skip')),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: _next,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                isLast
                                    ? tr('home.walkthrough.done')
                                    : tr('home.walkthrough.next'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate(key: ValueKey(_step))
                  .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: 240.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
