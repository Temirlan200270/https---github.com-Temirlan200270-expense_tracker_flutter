import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'animations/app_animations.dart';

/// Быстрые действия для главной страницы (Soft Buttons стиль)
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onExpense,
    required this.onIncome,
    this.onRepeatLast,
    this.hasLastTransaction = false,
  });

  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback? onRepeatLast;
  final bool hasLastTransaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              label: 'Расход',
              icon: Icons.arrow_downward_rounded,
              color: Colors.redAccent,
              onTap: onExpense,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              context,
              label: 'Доход',
              icon: Icons.arrow_upward_rounded,
              color: Colors.green,
              onTap: onIncome,
            ),
          ),
          if (onRepeatLast != null && hasLastTransaction) ...[
            const SizedBox(width: 16),
            _buildActionButton(
              context,
              label: 'Повторить',
              icon: Icons.repeat_rounded,
              color: Theme.of(context).colorScheme.primary,
              onTap: onRepeatLast!,
              isCompact: true,
            ),
          ],
        ],
      )
          .animate(effects: AppAnimations.fadeInUp),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    if (isCompact) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


