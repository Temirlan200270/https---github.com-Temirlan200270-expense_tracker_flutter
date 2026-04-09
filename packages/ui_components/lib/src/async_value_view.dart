import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.loadingWidget,
    this.errorBuilder,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) dataBuilder;
  final Widget? loadingWidget;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: dataBuilder,
      loading: () => loadingWidget ?? const Center(child: CircularProgressIndicator()),
      error: (error, stack) => errorBuilder?.call(error, stack) ??
          Center(
            child: Text(
              'Ошибка: $error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
    );
  }
}

