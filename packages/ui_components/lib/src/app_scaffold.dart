import 'package:flutter/material.dart';

class PrimaryScaffold extends StatelessWidget {
  const PrimaryScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.fab,
    this.bottomNavigationBar,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? fab;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        centerTitle: true,
        actions: actions,
      ),
      body: SafeArea(child: child),
      floatingActionButton: fab,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

