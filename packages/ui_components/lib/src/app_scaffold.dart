import 'package:flutter/material.dart';

import 'sss_screen_contract.dart';
import 'theme/visual_tokens.dart';

class PrimaryScaffold extends StatelessWidget {
  const PrimaryScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.appBarBottom,
    this.fab,
    this.bottomNavigationBar,
    this.contract,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;

  /// Нижняя зона AppBar (TabBar и т.п.).
  final PreferredSizeWidget? appBarBottom;
  final Widget? fab;
  final Widget? bottomNavigationBar;

  /// Контракт режима экрана (SSS): motion-профиль и запреты примитивов — см. [SssScreenContract].
  final SssScreenContract? contract;

  @override
  Widget build(BuildContext context) {
    final effective = contract ?? SssScreenContract.unspecified;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SssScreenContractScope(
      contract: effective,
      child: Scaffold(
        backgroundColor: SdsSurface.surface0(cs),
        appBar: AppBar(
          title: title != null ? Text(title!) : null,
          centerTitle: true,
          actions: actions,
          bottom: appBarBottom,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(child: child),
        floatingActionButton: fab,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

