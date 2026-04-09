import 'package:flutter/material.dart';

class PrimaryScaffold extends StatelessWidget {
  const PrimaryScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.fab,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        centerTitle: true,
        actions: actions,
      ),
      body: SafeArea(child: child),
      floatingActionButton: fab,
    );
  }
}

