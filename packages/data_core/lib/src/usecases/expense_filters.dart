import 'package:shared_models/shared_models.dart';

class ExpenseFilter {
  const ExpenseFilter({
    this.from,
    this.to,
    this.type,
    this.categoryIds = const [],
    this.searchTerm,
    this.limit = 50,
    this.offset = 0,
  });

  final DateTime? from;
  final DateTime? to;
  final ExpenseType? type;
  final List<String> categoryIds;
  final String? searchTerm;
  final int limit;
  final int offset;
}

