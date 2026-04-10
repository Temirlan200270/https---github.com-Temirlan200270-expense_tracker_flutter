# Визуальная регрессия (опционально)

Цель — ловить **визуальный drift** (отступы, цвет, типографика) при рефакторинге токенов, а не заменять ревью.

## 1. Golden tests (Flutter)

Встроенный механизм: `matchesGoldenFile` в `flutter_test`.

- Золотые эталоны — PNG в репозитории (обычно `test/goldens/`).
- Обновление после намеренного изменения UI:

```bash
flutter test --update-goldens
```

Рекомендации:

- Фиксировать **размер** виджета (`pumpWidget` + `SizedBox` или `MaterialApp` + `theme`), иначе диффы «плавают».
- Запускать на **той же платформе**, что и CI (часто **Linux**), либо использовать [golden_toolkit](https://pub.dev/packages/golden_toolkit) `DeviceBuilder` для нескольких размеров.
- Для компонентов из `ui_components` — тесты в `packages/ui_components/test/`, зависимость `flutter_test` уже в `pubspec.yaml`.

Минимальный скелет теста:

```dart
testWidgets('SurfaceCard matches golden', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SurfaceCard(
            child: SizedBox(width: 200, height: 80),
          ),
        ),
      ),
    ),
  );
  await expectLater(
    find.byType(SurfaceCard),
    matchesGoldenFile('goldens/surface_card.png'),
  );
});
```

## 2. Скриншот-diff (вне репозитория)

Инструменты уровня Percy / Chromatic / self-hosted screenshot CI дают дифф по всему экрану; полезны для **потоков** (импорт, аналитика). Требуют отдельной инфраструктуры и не обязательны для старта.

## 3. Связь с токенами

Смена `Sds*` должна давать **предсказуемый** дифф в голденах; если дифф «шумный» без смены токенов — упростить тест (фиксированная тема, размер, платформа).

См. также [DESIGN_SYSTEM.md §0.1](../DESIGN_SYSTEM.md) и [TOKEN_MIGRATION_MAP.md](TOKEN_MIGRATION_MAP.md).
