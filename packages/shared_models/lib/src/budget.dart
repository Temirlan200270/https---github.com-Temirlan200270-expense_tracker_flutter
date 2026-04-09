import 'package:uuid/uuid.dart';
import 'money.dart';

final _uuid = Uuid();

/// Период бюджета
enum BudgetPeriod {
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Еженедельно';
      case BudgetPeriod.monthly:
        return 'Ежемесячно';
      case BudgetPeriod.yearly:
        return 'Ежегодно';
    }
  }

  String get displayNameEn {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  /// Возвращает даты начала и конца текущего периода
  ({DateTime start, DateTime end}) getCurrentPeriodDates() {
    final now = DateTime.now();
    switch (this) {
      case BudgetPeriod.weekly:
        // Начало недели (понедельник)
        final weekday = now.weekday;
        final start = DateTime(now.year, now.month, now.day - (weekday - 1));
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return (start: start, end: end);
      case BudgetPeriod.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start: start, end: end);
      case BudgetPeriod.yearly:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return (start: start, end: end);
    }
  }
}

/// Бюджет с лимитом расходов
class Budget {
  Budget({
    String? id,
    required this.name,
    required this.limit,
    required this.period,
    this.categoryId,
    this.isActive = true,
    this.warningPercent = 80,
    this.notificationsEnabled = true,
    DateTime? createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String name; // Название бюджета (например, "Продукты", "Развлечения")
  final Money limit; // Лимит расходов
  final BudgetPeriod period;
  final String? categoryId; // Если null - общий бюджет на все категории
  final bool isActive;
  final int warningPercent; // Процент, при котором показывать предупреждение (по умолчанию 80%)
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  /// Вычисляет процент использования бюджета
  double calculateProgress(int spentInCents) {
    if (limit.amountInCents <= 0) return 0.0;
    return (spentInCents / limit.amountInCents).clamp(0.0, double.infinity);
  }

  /// Проверяет, достигнут ли порог предупреждения
  bool isWarningThresholdReached(int spentInCents) {
    final progress = calculateProgress(spentInCents);
    return progress >= warningPercent / 100;
  }

  /// Проверяет, превышен ли лимит
  bool isOverBudget(int spentInCents) {
    return spentInCents > limit.amountInCents;
  }

  /// Остаток бюджета в копейках
  int getRemainingInCents(int spentInCents) {
    return limit.amountInCents - spentInCents;
  }

  Budget copyWith({
    String? id,
    String? name,
    Money? limit,
    BudgetPeriod? period,
    String? categoryId,
    bool? isActive,
    int? warningPercent,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      warningPercent: warningPercent ?? this.warningPercent,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'limit': limit.toJson(),
        'period': period.name,
        'categoryId': categoryId,
        'isActive': isActive,
        'warningPercent': warningPercent,
        'notificationsEnabled': notificationsEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      name: json['name'] as String,
      limit: Money.fromJson(json['limit'] as Map<String, dynamic>),
      period: BudgetPeriod.values.firstWhere(
        (p) => p.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      categoryId: json['categoryId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      warningPercent: json['warningPercent'] as int? ?? 80,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
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

/// Расширенная модель бюджета с данными о текущих тратах
class BudgetWithSpending {
  const BudgetWithSpending({
    required this.budget,
    required this.spentInCents,
    this.categoryName,
  });

  final Budget budget;
  final int spentInCents; // Потрачено за текущий период
  final String? categoryName; // Название категории для отображения

  double get progress => budget.calculateProgress(spentInCents);
  bool get isWarning => budget.isWarningThresholdReached(spentInCents);
  bool get isOverBudget => budget.isOverBudget(spentInCents);
  int get remainingInCents => budget.getRemainingInCents(spentInCents);
  
  /// Цвет для прогресс-бара
  BudgetStatus get status {
    if (isOverBudget) return BudgetStatus.exceeded;
    if (isWarning) return BudgetStatus.warning;
    return BudgetStatus.normal;
  }
}

/// Статус бюджета для UI
enum BudgetStatus {
  normal,   // Зеленый - всё в порядке
  warning,  // Желтый/оранжевый - приближаемся к лимиту
  exceeded, // Красный - превышен
}

