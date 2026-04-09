import 'package:uuid/uuid.dart';

final _uuid = Uuid();

/// Правило автоматической категоризации транзакций
/// Когда в тексте транзакции встречается keyword, присваивается categoryId
class CategoryRule {
  CategoryRule({
    String? id,
    required this.keyword,
    required this.categoryId,
    this.priority = 0,
    this.caseSensitive = false,
    this.isActive = true,
    this.matchCount = 0,
    this.lastUsedAt,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String keyword; // Ключевое слово для поиска (например: "Magnum", "Glovo", "Netflix")
  final String categoryId; // ID категории для присвоения
  final int priority; // Приоритет правила (больше = выше)
  final bool caseSensitive; // Учитывать регистр при поиске
  final bool isActive; // Активно ли правило
  final int matchCount; // Сколько раз сработало правило
  final DateTime? lastUsedAt; // Когда последний раз сработало
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Проверяет, подходит ли текст под это правило
  bool matches(String text) {
    if (!isActive) return false;
    
    if (caseSensitive) {
      return text.contains(keyword);
    } else {
      return text.toLowerCase().contains(keyword.toLowerCase());
    }
  }

  CategoryRule copyWith({
    String? id,
    String? keyword,
    String? categoryId,
    int? priority,
    bool? caseSensitive,
    bool? isActive,
    int? matchCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryRule(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      isActive: isActive ?? this.isActive,
      matchCount: matchCount ?? this.matchCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Создаёт копию с увеличенным счётчиком срабатываний
  CategoryRule incrementMatchCount() {
    return copyWith(
      matchCount: matchCount + 1,
      lastUsedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'keyword': keyword,
        'categoryId': categoryId,
        'priority': priority,
        'caseSensitive': caseSensitive,
        'isActive': isActive,
        'matchCount': matchCount,
        'lastUsedAt': lastUsedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory CategoryRule.fromJson(Map<String, dynamic> json) {
    return CategoryRule(
      id: json['id'] as String,
      keyword: json['keyword'] as String,
      categoryId: json['categoryId'] as String,
      priority: json['priority'] as int? ?? 0,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      matchCount: json['matchCount'] as int? ?? 0,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  String toString() => 'CategoryRule(keyword: $keyword, categoryId: $categoryId, priority: $priority)';
}

/// Сервис для применения правил автокатегоризации
class CategoryRuleMatcher {
  CategoryRuleMatcher(this.rules);

  final List<CategoryRule> rules;

  /// Находит категорию для текста по правилам
  /// Возвращает null, если ни одно правило не подошло
  /// Если подошло несколько правил, выбирает по приоритету
  String? findCategoryId(String text) {
    if (text.isEmpty || rules.isEmpty) return null;

    CategoryRule? bestMatch;
    
    for (final rule in rules) {
      if (rule.matches(text)) {
        if (bestMatch == null || rule.priority > bestMatch.priority) {
          bestMatch = rule;
        }
      }
    }

    return bestMatch?.categoryId;
  }

  /// Находит правило, которое сработало для текста
  CategoryRule? findMatchingRule(String text) {
    if (text.isEmpty || rules.isEmpty) return null;

    CategoryRule? bestMatch;
    
    for (final rule in rules) {
      if (rule.matches(text)) {
        if (bestMatch == null || rule.priority > bestMatch.priority) {
          bestMatch = rule;
        }
      }
    }

    return bestMatch;
  }

  /// Применяет правила к списку текстов и возвращает Map<текст, categoryId>
  Map<String, String?> applyCategorization(List<String> texts) {
    return {
      for (final text in texts) text: findCategoryId(text),
    };
  }
}

