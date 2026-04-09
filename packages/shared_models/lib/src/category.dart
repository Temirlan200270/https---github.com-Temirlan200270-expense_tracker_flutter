import 'package:uuid/uuid.dart';

enum CategoryKind {
  expense,
  income;

  bool get isExpense => this == CategoryKind.expense;
}

class Category {
  Category({
    String? id,
    required this.name,
    required this.colorValue,
    required this.kind,
    DateTime? createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String name;
  final int colorValue;
  final CategoryKind kind;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  Category copyWith({
    String? id,
    String? name,
    int? colorValue,
    CategoryKind? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String?,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      kind: CategoryKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => CategoryKind.expense,
      ),
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

class DefaultCategories {
  static List<Category> expenses() => [
        Category(name: 'Продукты', colorValue: 0xFF4CAF50, kind: CategoryKind.expense),
        Category(name: 'Транспорт', colorValue: 0xFF2196F3, kind: CategoryKind.expense),
        Category(name: 'Развлечения', colorValue: 0xFF9C27B0, kind: CategoryKind.expense),
        Category(name: 'Здоровье', colorValue: 0xFFE53935, kind: CategoryKind.expense),
        Category(name: 'Коммунальные', colorValue: 0xFF6D4C41, kind: CategoryKind.expense),
      ];

  static List<Category> incomes() => [
        Category(name: 'Зарплата', colorValue: 0xFF2E7D32, kind: CategoryKind.income),
        Category(name: 'Фриланс', colorValue: 0xFF1976D2, kind: CategoryKind.income),
        Category(name: 'Инвестиции', colorValue: 0xFF512DA8, kind: CategoryKind.income),
      ];
}

