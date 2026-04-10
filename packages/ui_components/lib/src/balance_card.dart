import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'animations/app_animations.dart';

/// Hero карточка баланса с градиентом (Neo-bank стиль)
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.formatter,
    required this.themeType,
  });

  final double balance;
  final double income;
  final double expenses;
  final NumberFormat formatter;
  final String themeType; // 'purple', 'green', 'orange'

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(themeType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Общий баланс",
            style: GoogleFonts.manrope(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(balance),
            style: GoogleFonts.manrope(
              color: const Color(0xFFFFFFFF),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 600.ms,
                delay: 200.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMiniStat(
                Icons.arrow_downward_rounded,
                "Расходы",
                formatter.format(expenses),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms)
                  .slideX(begin: -0.1, end: 0, duration: 400.ms, delay: 400.ms),
              const Spacer(),
              _buildMiniStat(
                Icons.arrow_upward_rounded,
                "Доходы",
                formatter.format(income),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms)
                  .slideX(begin: 0.1, end: 0, duration: 400.ms, delay: 500.ms),
            ],
          ),
        ],
      ),
    )
        .animate(effects: AppAnimations.heroCard);
  }

  Widget _buildMiniStat(IconData icon, String label, String amount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFFFFFFF), size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.manrope(
                color: const Color(0xFFFFFFFF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  LinearGradient _getGradient(String themeType) {
    switch (themeType) {
      case 'green':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50), // Green
            Color(0xFF66BB6A), // Light Green
          ],
        );
      case 'orange':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9800), // Orange
            Color(0xFFFFB74D), // Light Orange
          ],
        );
      default: // purple
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B4CFF), // Purple
            Color(0xFF9174FF), // Light Purple
          ],
        );
    }
  }
}

