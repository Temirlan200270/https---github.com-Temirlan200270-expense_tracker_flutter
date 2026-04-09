import 'package:uuid/uuid.dart';
import 'money.dart';

final _uuid = Uuid();

/// Тип долга
enum DebtType {
  iOwe,    // Я должен (Кредит)
  theyOwe, // Мне должны (Дебиторская задолженность)
}

extension DebtTypeExtension on DebtType {
  String get displayName {
    switch (this) {
      case DebtType.iOwe:
        return 'Я должен';
      case DebtType.theyOwe:
        return 'Мне должны';
    }
  }

  String get displayNameEn {
    switch (this) {
      case DebtType.iOwe:
        return 'I Owe';
      case DebtType.theyOwe:
        return 'They Owe';
    }
  }
}

/// Долг
class Debt {
  Debt({
    String? id,
    required this.personName,
    required this.totalAmount,
    Money? repaidAmount,
    required this.type,
    this.dueDate,
    this.isClosed = false,
    this.comment,
    DateTime? createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  })  : id = id ?? _uuid.v4(),
        repaidAmount = repaidAmount ?? Money(amountInCents: 0, currencyCode: totalAmount.currencyCode),
        createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String personName; // Имя человека
  final Money totalAmount; // Общая сумма долга
  final Money repaidAmount; // Сколько уже возвращено
  final DebtType type;
  final DateTime? dueDate; // Дата возврата (опционально)
  final bool isClosed; // Закрыт ли долг
  final String? comment; // Комментарий
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  /// Остаток долга
  Money get remainingAmount {
    final remaining = totalAmount.amountInCents - repaidAmount.amountInCents;
    return Money(
      amountInCents: remaining.clamp(0, totalAmount.amountInCents),
      currencyCode: totalAmount.currencyCode,
    );
  }

  /// Прогресс погашения (0.0 - 1.0)
  double get progress {
    if (totalAmount.amountInCents <= 0) return 0.0;
    return (repaidAmount.amountInCents / totalAmount.amountInCents).clamp(0.0, 1.0);
  }

  /// Проверяет, полностью ли погашен долг
  bool get isFullyRepaid => remainingAmount.amountInCents <= 0;

  /// Проверяет, просрочен ли долг
  bool get isOverdue {
    if (dueDate == null || isClosed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  Debt copyWith({
    String? id,
    String? personName,
    Money? totalAmount,
    Money? repaidAmount,
    DebtType? type,
    DateTime? dueDate,
    bool? isClosed,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      totalAmount: totalAmount ?? this.totalAmount,
      repaidAmount: repaidAmount ?? this.repaidAmount,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isClosed: isClosed ?? this.isClosed,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Добавить сумму к погашению
  Debt addRepayment(Money amount) {
    final newRepaid = Money(
      amountInCents: repaidAmount.amountInCents + amount.amountInCents,
      currencyCode: repaidAmount.currencyCode,
    );
    return copyWith(
      repaidAmount: newRepaid,
      isClosed: newRepaid.amountInCents >= totalAmount.amountInCents,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'totalAmount': totalAmount.toJson(),
        'repaidAmount': repaidAmount.toJson(),
        'type': type.name,
        'dueDate': dueDate?.toIso8601String(),
        'isClosed': isClosed,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      personName: json['personName'] as String,
      totalAmount: Money.fromJson(json['totalAmount'] as Map<String, dynamic>),
      repaidAmount: json['repaidAmount'] != null
          ? Money.fromJson(json['repaidAmount'] as Map<String, dynamic>)
          : Money(amountInCents: 0, currencyCode: Money.fromJson(json['totalAmount'] as Map<String, dynamic>).currencyCode),
      type: DebtType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DebtType.theyOwe,
      ),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isClosed: json['isClosed'] as bool? ?? false,
      comment: json['comment'] as String?,
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

