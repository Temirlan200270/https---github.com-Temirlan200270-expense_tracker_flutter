import 'money.dart';

enum ExpenseType {
  income,
  expense;

  bool get isIncome => this == ExpenseType.income;
  bool get isExpense => this == ExpenseType.expense;
}

class Expense {
  Expense({
    required this.id,
    required this.amount,
    required this.type,
    required this.occurredAt,
    this.categoryId,
    this.note,
    DateTime? createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final Money amount;
  final ExpenseType type;
  final DateTime occurredAt;
  final String? categoryId;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  Expense copyWith({
    String? id,
    Money? amount,
    ExpenseType? type,
    DateTime? occurredAt,
    String? categoryId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount.toJson(),
        'type': type.name,
        'occurredAt': occurredAt.toIso8601String(),
        'categoryId': categoryId,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      type: ExpenseType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => ExpenseType.expense,
      ),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      categoryId: json['categoryId'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: (json['updatedAt'] as String?)?.let(DateTime.parse),
      deletedAt: (json['deletedAt'] as String?)?.let(DateTime.parse),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

extension _NullableStringParsing on String? {
  T? let<T>(T Function(String value) mapper) {
    final value = this;
    if (value == null) return null;
    return mapper(value);
  }
}

