import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

/// Поле поиска категорий с выпадающим списком
class CategorySearchField extends StatefulWidget {
  const CategorySearchField({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.type,
    this.categorizationConfidence,
    this.highlightSuggested = false,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final ExpenseType type;

  /// Уверенность pipeline (null — нет подсказки или выбор пользователя).
  final double? categorizationConfidence;

  /// Лёгкая подсветка: категория совпала с авто-подсказкой pipeline (ещё не зафиксирована вручную).
  final bool highlightSuggested;

  @override
  State<CategorySearchField> createState() => _CategorySearchFieldState();
}

class _CategorySearchFieldState extends State<CategorySearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = _getFilteredCategories('');
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
    
    // Устанавливаем текст выбранной категории
    if (widget.selectedCategoryId != null) {
      final category = widget.categories.firstWhere(
        (c) => c.id == widget.selectedCategoryId,
        orElse: () => widget.categories.first,
      );
      _controller.text = category.name;
    }
  }

  @override
  void didUpdateWidget(CategorySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      if (widget.selectedCategoryId != null) {
        final category = widget.categories.firstWhere(
          (c) => c.id == widget.selectedCategoryId,
          orElse: () => widget.categories.first,
        );
        _controller.text = category.name;
      } else {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCategories = _getFilteredCategories(_controller.text);
      _showSuggestions = _controller.text.isNotEmpty && _filteredCategories.isNotEmpty;
    });
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && 
          _controller.text.isNotEmpty && 
          _filteredCategories.isNotEmpty;
    });
  }

  List<Category> _getFilteredCategories(String query) {
    final filtered = widget.categories
        .where((category) => 
            category.kind == (widget.type.isIncome ? CategoryKind.income : CategoryKind.expense))
        .toList();

    if (query.isEmpty) {
      return filtered;
    }

    final lowerQuery = query.toLowerCase();
    return filtered.where((category) {
      return category.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  void _selectCategory(Category category) {
    _controller.text = category.name;
    widget.onCategorySelected(category.id);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  void _clearCategory() {
    _controller.clear();
    widget.onCategorySelected(null);
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suggest = widget.highlightSuggested && widget.selectedCategoryId != null;
    final accent = cs.primary;
    final borderColor =
        suggest ? accent.withValues(alpha: 0.55) : cs.outlineVariant;
    final borderWidth = suggest ? 2.0 : 1.0;
    final radius = BorderRadius.circular(16);

    OutlineInputBorder borderFor({required bool focused}) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: focused ? accent : borderColor,
          width: focused ? 2.0 : borderWidth,
        ),
      );
    }

    final field = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: tr('expenses.form.category'),
        hintText: tr('expenses.form.category_hint'),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: _clearCategory,
              )
            : Icon(
                suggest ? Icons.auto_awesome_rounded : Icons.search_rounded,
                color: suggest ? accent.withValues(alpha: 0.9) : null,
              ),
        prefixIcon: AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: AppMotion.curve,
          switchOutCurve: AppMotion.curveReverse,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: widget.selectedCategoryId != null
              ? Container(
                  key: ValueKey<String>('cat-${widget.selectedCategoryId}'),
                  margin: const EdgeInsets.all(8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(
                      widget.categories
                          .firstWhere((c) => c.id == widget.selectedCategoryId)
                          .colorValue,
                    ),
                    shape: BoxShape.circle,
                  ),
                )
              : Container(
                  key: const ValueKey<String>('cat-none'),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: borderFor(focused: false),
        enabledBorder: borderFor(focused: false),
        focusedBorder: borderFor(focused: true),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      onChanged: (_) => _onSearchChanged(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        suggest
            ? AnimatedContainer(
                duration: AppMotion.standard,
                curve: AppMotion.curve,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: field,
              )
            : field,
        if (_showSuggestions && _filteredCategories.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                return InkWell(
                  onTap: () => _selectCategory(category),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(category.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (_controller.text.isNotEmpty && _filteredCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              tr('expenses.form.category_not_found'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        if (widget.categorizationConfidence != null &&
            widget.categorizationConfidence! > 0 &&
            widget.categorizationConfidence! < 1.0 &&
            widget.selectedCategoryId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('expenses.form.category_uncertain_hint'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

