import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// Вертикальная сетка главной: единственный источник внешних отступов экрана.
/// Значения = [SdsSpacing] (сетка 4 pt).
abstract final class HomeLayoutSpacing {
  static const double s8 = SdsSpacing.xs;
  static const double s12 = SdsSpacing.sm;
  static const double s16 = SdsSpacing.md;
  static const double s20 = SdsSpacing.lg;
  static const double s24 = SdsSpacing.xl;
  static const double s32 = SdsSpacing.xxl;
  static const double s40 = SdsSpacing.section;
  static const double s56 = SdsSpacing.navFeed;

  /// Горизонтальный ритм для слота Hero (и связанных CTA под карточкой).
  static const EdgeInsets horizontal =
      EdgeInsets.symmetric(horizontal: SdsSpacing.lg);

  /// Обёртка ленты операций (нижний отступ — запас над FAB и нижней навигацией).
  static const EdgeInsets feedOuter = EdgeInsets.fromLTRB(
    SdsSpacing.lg,
    0,
    SdsSpacing.lg,
    SdsSpacing.navFeed,
  );
}

/// Каркас скролла Home: слоты header → hero → (опц.) заголовок ленты → slivers ленты.
///
/// Hero и CTA под ним живут в одном горизонтально ограниченном столбце — визуальный «якорь» экрана.
class HomeLayoutShell extends StatelessWidget {
  const HomeLayoutShell({
    super.key,
    required this.physics,
    required this.header,
    required this.hero,
    this.feedHeader,
    this.feedSlivers = const [],
    this.bottomSpacerHeight,
  });

  final ScrollPhysics physics;
  final Widget header;
  final Widget hero;
  final Widget? feedHeader;
  final List<Widget> feedSlivers;
  final double? bottomSpacerHeight;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: physics,
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverToBoxAdapter(
          child: Padding(
            padding: HomeLayoutSpacing.horizontal,
            child: hero,
          ),
        ),
        if (feedHeader != null) SliverToBoxAdapter(child: feedHeader!),
        ...feedSlivers,
        if (bottomSpacerHeight != null)
          SliverToBoxAdapter(
            child: SizedBox(height: bottomSpacerHeight!),
          ),
      ],
    );
  }
}
