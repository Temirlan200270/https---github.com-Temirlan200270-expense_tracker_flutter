import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_core/data_core.dart';

import '../../providers/expenses_providers.dart';

class ExpenseSearchField extends ConsumerStatefulWidget {
  const ExpenseSearchField({super.key});

  @override
  ConsumerState<ExpenseSearchField> createState() => _ExpenseSearchFieldState();
}

class _ExpenseSearchFieldState extends ConsumerState<ExpenseSearchField> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(expenseFilterProvider);
    _controller.text = currentFilter.searchTerm ?? '';
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final searchTerm = _controller.text.trim();
      final currentFilter = ref.read(expenseFilterProvider);
      ref.read(expenseFilterProvider.notifier).state = ExpenseFilter(
        from: currentFilter.from,
        to: currentFilter.to,
        type: currentFilter.type,
        categoryIds: currentFilter.categoryIds,
        searchTerm: searchTerm.isEmpty ? null : searchTerm,
        limit: currentFilter.limit,
        offset: currentFilter.offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: tr('filters.search_hint'),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                },
              )
            : null,
      ),
    );
  }
}

