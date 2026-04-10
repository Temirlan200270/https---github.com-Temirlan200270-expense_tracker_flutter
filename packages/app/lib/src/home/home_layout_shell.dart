import 'package:flutter/material.dart';

/// Вертикальная сетка главной: единственный источник внешних отступов экрана.
abstract final class HomeLayoutSpacing {
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;

  /// Горизонтальный ритм для слота Hero (и связанных CTA под карточкой).
  static const EdgeInsets horizontal = EdgeInsets.symmetric(horizontal: s20);

  /// Обёртка ленты операций (нижний отступ — запас над панелью навигации при скролле).
  static const EdgeInsets feedOuter = EdgeInsets.fromLTRB(s20, 0, s20, s40);
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
