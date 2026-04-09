import 'expense.dart';
import 'money.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

/// Тип повторения транзакции
enum RecurrenceType {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceType.daily:
        return 'Ежедневно';
      case RecurrenceType.weekly:
        return 'Еженедельно';
      case RecurrenceType.monthly:
        return 'Ежемесячно';
      case RecurrenceType.yearly:
        return 'Ежегодно';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }
}

/// Повторяющаяся транзакция (подписка)
class RecurringExpense {
  RecurringExpense({
    String? id,
    required this.name,
    required this.amount,
    required this.type,
    required this.recurrenceType,
    required this.startDate,
    this.endDate,
    this.categoryId,
    this.note,
    this.isActive = true,
    this.lastGenerated,
    DateTime? nextOccurrence,
    DateTime? createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        nextOccurrence = nextOccurrence ?? _calculateNextOccurrence(startDate, recurrenceType);

  final String id;
  final String name; // Название подписки (например, "Netflix", "Аренда")
  final Money amount;
  final ExpenseType type;
  final RecurrenceType recurrenceType;
  final DateTime startDate;
  final DateTime? endDate; // Опциональная дата окончания
  final String? categoryId;
  final String? note;
  final bool isActive; // Активна ли подписка
  final DateTime? lastGenerated; // Когда последний раз создавалась транзакция
  final DateTime? nextOccurrence; // Следующая дата создания транзакции
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  /// Вычисляет следующую дату создания транзакции
  static DateTime _calculateNextOccurrence(DateTime startDate, RecurrenceType type) {
    final now = DateTime.now();
    DateTime next = startDate;

    while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      switch (type) {
        case RecurrenceType.daily:
          next = next.add(const Duration(days: 1));
          break;
        case RecurrenceType.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case RecurrenceType.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case RecurrenceType.yearly:
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
    }

    return next;
  }

  /// Вычисляет следующую дату на основе текущей
  DateTime calculateNextOccurrence(DateTime current) {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return current.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return current.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case RecurrenceType.yearly:
        return DateTime(current.year + 1, current.month, current.day);
    }
  }

  /// Проверяет, нужно ли создать транзакцию сейчас
  bool shouldGenerateNow() {
    if (!isActive) return false;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return false;
    if (nextOccurrence == null) return false;
    return DateTime.now().isAfter(nextOccurrence!) || 
           DateTime.now().isAtSameMomentAs(nextOccurrence!);
  }

  /// Создаёт транзакцию на основе этой подписки
  Expense generateExpense() {
    final now = DateTime.now();
    return Expense(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      occurredAt: now,
      categoryId: categoryId,
      note: note ?? name,
    );
  }

  RecurringExpense copyWith({
    String? id,
    String? name,
    Money? amount,
    ExpenseType? type,
    RecurrenceType? recurrenceType,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? note,
    bool? isActive,
    DateTime? lastGenerated,
    DateTime? nextOccurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount.toJson(),
        'type': type.name,
        'recurrenceType': recurrenceType.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'categoryId': categoryId,
        'note': note,
        'isActive': isActive,
        'lastGenerated': lastGenerated?.toIso8601String(),
        'nextOccurrence': nextOccurrence?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      type: ExpenseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExpenseType.expense,
      ),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrenceType'],
        orElse: () => RecurrenceType.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String)
          : null,
      categoryId: json['categoryId'] as String?,
      note: json['note'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastGenerated: json['lastGenerated'] != null
          ? DateTime.parse(json['lastGenerated'] as String)
          : null,
      nextOccurrence: json['nextOccurrence'] != null
          ? DateTime.parse(json['nextOccurrence'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

