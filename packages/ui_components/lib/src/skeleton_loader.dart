import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Skeleton loader для карточек транзакций
class ExpenseSkeletonCard extends StatelessWidget {
  const ExpenseSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _SkeletonBox(size: 48, circular: true),
        title: _SkeletonBox(height: 16, width: 120),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _SkeletonBox(height: 12, width: 80),
        ),
        trailing: _SkeletonBox(height: 16, width: 60),
      ),
    );
  }
}

/// Skeleton loader для списка
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder ?? (context, index) => const ExpenseSkeletonCard(),
    );
  }
}

/// Базовый skeleton box с shimmer эффектом (flutter_animate)
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height = 16,
    this.circular = false,
    this.size,
  });

  final double? width;
  final double height;
  final bool circular;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? height;
    final width = this.width ?? (circular ? size : 100);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      width: width,
      height: circular ? size : height,
      decoration: BoxDecoration(
        color: baseColor,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(4),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1100.ms,
          color: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        );
  }
}

