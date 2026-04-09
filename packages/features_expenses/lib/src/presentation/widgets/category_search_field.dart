import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Поле поиска категорий с выпадающим списком
class CategorySearchField extends StatefulWidget {
  const CategorySearchField({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.type,
    this.categorizationConfidence,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final ExpenseType type;

  /// Уверенность pipeline (null — нет подсказки или выбор пользователя).
  final double? categorizationConfidence;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: tr('expenses.form.category'),
            hintText: tr('expenses.form.category_hint'),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _clearCategory,
                  )
                : const Icon(Icons.search),
            prefixIcon: widget.selectedCategoryId != null
                ? Container(
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
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          ),
          onChanged: (_) => _onSearchChanged(),
        ),
        if (_showSuggestions && _filteredCategories.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
                color: Colors.grey,
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
                  Icons.info_outline,
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

