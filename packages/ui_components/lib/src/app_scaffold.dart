import 'package:flutter/material.dart';

import 'sss_screen_contract.dart';

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
    return SssScreenContractScope(
      contract: effective,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: title != null ? Text(title!) : null,
          centerTitle: true,
          actions: actions,
          bottom: appBarBottom,
        ),
        body: SafeArea(child: child),
        floatingActionButton: fab,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

