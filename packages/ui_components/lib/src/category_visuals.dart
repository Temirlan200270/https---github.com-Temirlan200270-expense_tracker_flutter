import 'package:flutter/material.dart';

/// Иконки категорий: семантика по имени → иначе стабильный хеш по [categoryId].
abstract final class CategoryVisuals {
  CategoryVisuals._();

  static const List<IconData> _expenseIcons = [
    Icons.shopping_bag_outlined,
    Icons.restaurant_outlined,
    Icons.directions_car_outlined,
    Icons.movie_outlined,
    Icons.local_hospital_outlined,
    Icons.home_outlined,
    Icons.sports_esports_outlined,
    Icons.pets_outlined,
    Icons.flight_outlined,
    Icons.phone_android_outlined,
    Icons.receipt_long_outlined,
    Icons.coffee_outlined,
  ];

  static const List<IconData> _incomeIcons = [
    Icons.payments_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.savings_outlined,
    Icons.trending_up_outlined,
    Icons.work_outline_rounded,
    Icons.attach_money_outlined,
  ];

  /// Полный путь: имя (ключевые слова / дефолтные категории) → иначе [iconFor].
  static IconData iconForCategory({
    required String categoryId,
    required bool isExpenseCategory,
    String? name,
  }) {
    final semantic = _semanticIcon(name, isExpenseCategory);
    if (semantic != null) return semantic;
    return iconFor(categoryId, isExpenseCategory: isExpenseCategory);
  }

  /// Только хеш по id (fallback).
  static IconData iconFor(String categoryId, {required bool isExpenseCategory}) {
    final pool = isExpenseCategory ? _expenseIcons : _incomeIcons;
    final i = categoryId.hashCode.abs() % pool.length;
    return pool[i];
  }

  static IconData? _semanticIcon(String? name, bool expense) {
    if (name == null || name.trim().isEmpty) return null;
    final n = _normalize(name);

    if (expense) {
      for (final m in _expenseMatchers) {
        if (m.keys.any((k) => n.contains(k))) return m.icon;
      }
    } else {
      for (final m in _incomeMatchers) {
        if (m.keys.any((k) => n.contains(k))) return m.icon;
      }
    }
    return null;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _KeywordIcon {
  const _KeywordIcon(this.keys, this.icon);

  final List<String> keys;
  final IconData icon;
}

/// RU + EN ключевые слова; порядок — от более специфичных к общим при необходимости.
const List<_KeywordIcon> _expenseMatchers = [
  _KeywordIcon(
    [
      'продукт',
      'продукты',
      'еда',
      'супермаркет',
      'магазин',
      'food',
      'grocery',
      'groceries',
    ],
    Icons.restaurant_outlined,
  ),
  _KeywordIcon(
    [
      'транспорт',
      'такси',
      'uber',
      'авто',
      'бензин',
      'парковк',
      'transport',
      'car',
      'fuel',
      'parking',
    ],
    Icons.directions_car_outlined,
  ),
  _KeywordIcon(
    [
      'развлечен',
      'кино',
      'игр',
      'entertainment',
      'games',
      'hobby',
    ],
    Icons.movie_outlined,
  ),
  _KeywordIcon(
    [
      'здоровь',
      'медицин',
      'аптек',
      'врач',
      'health',
      'medical',
      'pharmacy',
      'doctor',
    ],
    Icons.local_hospital_outlined,
  ),
  _KeywordIcon(
    [
      'коммунал',
      'жкх',
      'аренд',
      'квартир',
      'utilities',
      'rent',
      'housing',
    ],
    Icons.home_outlined,
  ),
  _KeywordIcon(
    [
      'одежд',
      'шопинг',
      'clothes',
      'shopping',
      'fashion',
    ],
    Icons.shopping_bag_outlined,
  ),
  _KeywordIcon(
    [
      'связь',
      'телефон',
      'интернет',
      'mobile',
      'phone',
      'internet',
      'subscription',
      'подписк',
    ],
    Icons.phone_android_outlined,
  ),
  _KeywordIcon(
    [
      'путешеств',
      'отпуск',
      'авиа',
      'travel',
      'flight',
      'hotel',
    ],
    Icons.flight_outlined,
  ),
  _KeywordIcon(
    [
      'кредит',
      'ипотек',
      'loan',
      'mortgage',
    ],
    Icons.account_balance_outlined,
  ),
];

const List<_KeywordIcon> _incomeMatchers = [
  _KeywordIcon(
    [
      'зарплат',
      'оклад',
      'salary',
      'payroll',
      'wage',
    ],
    Icons.payments_outlined,
  ),
  _KeywordIcon(
    [
      'фриланс',
      'freelance',
      'контракт',
      'contract',
    ],
    Icons.work_outline_rounded,
  ),
  _KeywordIcon(
    [
      'инвест',
      'дивиденд',
      'акци',
      'invest',
      'dividend',
      'stock',
    ],
    Icons.savings_outlined,
  ),
  _KeywordIcon(
    [
      'кэшбэк',
      'возврат',
      'cashback',
      'refund',
    ],
    Icons.replay_outlined,
  ),
  _KeywordIcon(
    [
      'подар',
      'gift',
      'бонус',
      'bonus',
    ],
    Icons.card_giftcard_outlined,
  ),
];
