# SSS Presentation Layer Standard v1

**Назначение:** универсальный стандарт маппинга `Domain → UI` для всех экранов продукта. Гарантирует, что виджеты **не знают** про провайдеры данных, а рендерят готовые presentation model'и.

**Принцип:** UI-виджет — **dumb view**. Он получает модель и рисует. Маппинг, fallback-логика, категории, цвета — в чистой функции-маппере. Провайдер склеивает домен и маппер.

---

## 1. Три слоя Presentation Pipeline

```text
┌─────────────────────────────────────────────────────┐
│  1. Domain Layer                                     │
│     Expense, Category, Budget, FinancialSnapshot     │
│     ↓                                                │
│  2. Mapper (pure function, no ref, no context)       │
│     mapExpenseToTile(), mapBudgetToCard(), ...        │
│     ↓                                                │
│  3. Presentation Model (@immutable)                  │
│     ExpenseTileModel, BudgetCardModel, ...           │
│     ↓                                                │
│  4. Provider (Riverpod, single subscription)         │
│     homeFeedTilesProvider, budgetCardsProvider, ...   │
│     ↓                                                │
│  5. Widget (dumb view, accepts model)                │
│     HomeFeedCard, BudgetCard, ...                    │
└─────────────────────────────────────────────────────┘
```

### Правило потока данных

```text
Domain Entity → Mapper → PresentationModel → Provider → Widget
       ↑                                                  │
       └─── actions (delete, edit) ────────────────────────┘
```

Виджет может вызывать **действия** через `ref.read(repo)` — но **не читает** доменные провайдеры для рендера.

---

## 2. Naming Convention

| Слой | Суффикс / паттерн | Пример |
|------|-------------------|--------|
| Presentation Model | `*TileModel`, `*CardModel`, `*SectionModel` | `ExpenseTileModel`, `BudgetCardModel` |
| Mapper function | `map*To*()` | `mapExpenseToTile()`, `mapBudgetToCard()` |
| Provider | `*TilesProvider`, `*CardsProvider` | `homeFeedTilesProvider`, `budgetCardsProvider` |
| Widget | название без Model | `HomeFeedCard`, `BudgetCard` |

### Файловая структура (на экран)

```text
feature_or_screen/
├── *_tile_model.dart     — model + mapper (pure)
├── *_provider.dart       — Riverpod provider (single subscription)
├── *_card.dart           — dumb widget
```

---

## 3. Presentation Model — контракт

```dart
@immutable
class SomeTileModel {
  const SomeTileModel({...});

  // ✅ Доменная сущность (для actions: delete, edit, duplicate)
  final DomainEntity entity;

  // ✅ Готовые строки (title, subtitle, formatted amount)
  final String title;
  final String? subtitle;

  // ✅ Сырые данные для theme-dependent resolve (цвет категории как int)
  final int? colorValue;

  // ✅ resolve-методы для theme-dependent визуалов
  IconData resolveIcon();
  Color resolveIconBackground(ColorScheme cs);
  Color resolveIconForeground(ColorScheme cs);
}
```

### Что МОЖНО в модели

| Можно | Почему |
|-------|--------|
| `resolveIcon()` — pure по полям модели | Зависит только от данных модели, детерминированно |
| `resolveColor(ColorScheme cs)` — принимает тему | `ColorScheme` — value object, не runtime dependency |
| `formattedAmount` как готовая строка | Маппер форматирует один раз |

### Что НЕЛЬЗЯ в модели

| Нельзя | Почему |
|--------|--------|
| `ref.watch(...)` | Модель — не виджет, не имеет Riverpod scope |
| `BuildContext` | Модель — не виджет |
| `Theme.of(context)` | Это widget-layer; используй `ColorScheme` параметром |
| Бизнес-логика (if budget exceeded → ...) | Это domain layer; маппер решает и кладёт результат в поле |
| Мутации (delete, save) | Это action layer; виджет вызывает через `ref.read` |

---

## 4. Mapper — контракт

```dart
ExpenseTileModel mapExpenseToTile({
  required Expense expense,
  required List<Category> categories,
  required String Function(bool isIncome) fallbackTitle,
})
```

### Правила маппера

1. **Pure function** — без `ref`, без `context`, без side effects.
2. **Один маппер на один тип модели** — `mapExpenseToTile`, `mapBudgetToCard`.
3. **Fallback-логика внутри маппера** — если нет категории, маппер ставит `null`, модель знает fallback через `resolve*()`.
4. **Тестируемый без Flutter** — только `dart:core` + domain entities.

### Тест маппера (пример)

```dart
test('mapExpenseToTile — with category', () {
  final model = mapExpenseToTile(
    expense: testExpense,
    categories: [testCategory],
    fallbackTitle: (isIncome) => isIncome ? 'Income' : 'Expense',
  );
  expect(model.categoryName, 'Продукты');
  expect(model.categoryColorValue, 0xFF4CAF50);
  expect(model.title, testExpense.note);
});

test('mapExpenseToTile — no category, no note', () {
  final model = mapExpenseToTile(
    expense: testExpense.copyWith(categoryId: null, note: null),
    categories: [],
    fallbackTitle: (isIncome) => isIncome ? 'Income' : 'Expense',
  );
  expect(model.categoryName, isNull);
  expect(model.title, 'Expense');
});
```

---

## 5. Provider — контракт

```dart
final someTilesProvider = Provider.autoDispose<List<SomeTileModel>>((ref) {
  final entities = ref.watch(entitiesStreamProvider).valueOrNull;
  final lookup = ref.watch(lookupStreamProvider).valueOrNull;
  if (entities == null) return const [];
  return entities.map((e) => mapEntityToTile(e, lookup ?? [])).toList();
});
```

### Правила провайдера

1. **Одна подписка вместо N** — провайдер `watch`'ит потоки, карточки не `watch`'ат.
2. **`autoDispose`** — не держим данные, когда экран не виден.
3. **`valueOrNull` + empty fallback** — graceful loading, без `when` в провайдере.
4. **Не кэшировать бесконечно** — если список растёт, `.take(limit)`.

---

## 6. Widget — контракт

```dart
class SomeCard extends StatelessWidget {  // или ConsumerStatefulWidget для actions
  const SomeCard({super.key, required this.model, required this.formatter});

  final SomeTileModel model;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // model.resolveIcon(), model.resolveIconBackground(cs), model.title — всё готово
  }
}
```

### Правила виджета

1. **Принимает модель, не доменную сущность** — `SomeTileModel`, не `Expense + Category`.
2. **Нет `ref.watch` для данных рендера** — только `ref.read` для действий (delete, edit).
3. **Theme-dependent визуалы через `resolve*(ColorScheme)`** — не хардкод цветов.
4. **Если нужен `ConsumerStatefulWidget`** — только для действий (swipe delete, context menu), не для данных.

---

## 7. Когда НЕ нужен Presentation Model

| Случай | Почему model не нужен |
|--------|-----------------------|
| Виджет принимает 1–2 примитива | Overhead модели больше, чем польза |
| Данные уже в нужном формате | Маппер — identity function |
| Одноразовый виджет без переиспользования | Нет риска дублирования |

**Правило:** если виджет делает `ref.watch` + цикл/lookup + маппинг внутри `build()` — нужен Presentation Model.

---

## 8. Масштабирование на другие экраны

### Home (DONE)

```text
Expense + Category → mapExpenseToTile → ExpenseTileModel → homeFeedTilesProvider → HomeFeedCard
```

### Budget (target)

```text
BudgetWithSpending → mapBudgetToCard → BudgetCardModel → budgetCardsProvider → BudgetCard
```

### Analytics (target)

```text
CategoryBreakdown → mapBreakdownToBar → BreakdownBarModel → breakdownBarsProvider → BreakdownBar
```

### Expenses List (target)

Переиспользовать `ExpenseTileModel` + `mapExpenseToTile`. Другой провайдер (полный список вместо `.take(5)`), тот же маппер.

---

## 9. Governor (нарушения = блокер PR)

| Запрещено | Альтернатива |
|-----------|-------------|
| `ref.watch(dataProvider)` внутри `build()` карточки списка | Presentation Model + provider |
| Lookup категории / бюджета в виджете | Маппер |
| `Color(entity.colorValue)` в `build()` | `model.resolveIconBackground(cs)` |
| Форматирование amount в `build()` | Маппер кладёт `formattedAmount` или виджет получает `NumberFormat` |
| `dynamic` или `Object?` в модели | Strict typing, все поля final |

---

## 10. Связанные документы

| Артефакт | Путь |
|----------|------|
| Home Architecture v3 | `docs/SSS_HOME_ARCHITECTURE_V3.md` |
| SSS UI System v2 | `docs/SSS_UI_SYSTEM_V2.md` |
| Design System | `DESIGN_SYSTEM.md` |
| Architecture | `ARCHITECTURE.md` |
| ExpenseTileModel (reference impl) | `packages/app/lib/src/home/home_feed_tile_model.dart` |
| Feed provider (reference impl) | `packages/app/lib/src/home/home_feed_provider.dart` |
| Feed card (reference impl) | `packages/app/lib/src/home/home_feed_card.dart` |
