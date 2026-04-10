# Legacy → `Sds*` (карта миграции)

Единый источник в коде: `packages/ui_components/lib/src/theme/visual_tokens.dart`.

При правке файла во `features_*` убирайте «сырые» числа в пользу токенов ниже. Строгая проверка (после завершения миграции): `dart tool/sss_ui_audit.dart --strict --token-strict` (см. [SSS_UI_SYSTEM_V2.md §8](SSS_UI_SYSTEM_V2.md)).

---

## Отступы и сетка (4 pt)

| Legacy | Token |
|--------|--------|
| 4 px | `SdsSpacing.xxs` |
| 8 px | `SdsSpacing.xs` |
| 12 px | `SdsSpacing.sm` |
| **16 px** | **`SdsSpacing.md`** |
| 20 px | `SdsSpacing.lg` |
| 24 px | `SdsSpacing.xl` |
| 28 px | `SdsSpacing.xlPlus` |
| 32 px | `SdsSpacing.xxl` |
| 40 px | `SdsSpacing.section` |
| 56 px | `SdsSpacing.navFeed` |
| max width empty/error 416 | `SdsLayout.emptyStateMaxWidth` |

---

## Радиусы

| Legacy | Token |
|--------|--------|
| 16 | `SdsRadius.sm` |
| 20 | `SdsRadius.md` |
| 24 | `SdsRadius.lg` |
| 28 (hero) | `SdsRadius.xl` |

---

## Тени

Использовать **`SdsElevation.softHero` / `softCard` / `softTile`** (`ColorScheme` передаётся в метод).

---

## Альфа: текст на обычной поверхности (`onSurface`)

| Legacy | Token |
|--------|--------|
| ~0.72 вторичный текст | **`SdsOnSurface.secondary`** |
| ~0.45 подписи / muted label | **`SdsOnSurface.tertiary`** |

> Раньше обсуждалось имя `SdsEmphasis.bodySecondary` — **не используем**; актуально только **`SdsOnSurface.secondary`**.

---

## Альфа: текст/линии на градиенте (белый контент)

| Контекст | Token |
|----------|--------|
| Основной белый текст | `SdsOnGradient.label` |
| Приглушённый | `SdsOnGradient.muted` |
| Разделитель | `SdsOnGradient.divider` |

---

## Обводки и разделители

| Legacy | Token |
|--------|--------|
| ~0.35 `outlineVariant` | `SdsStroke.subtle` |
| ~0.4 divider | `SdsStroke.medium` |
| ~0.22 `outline` | `SdsStroke.hairline` |

---

## Заливки поверх surface

| Legacy | Token |
|--------|--------|
| ~0.35 «круг кнопки» / подложка | `SdsFill.surfaceMuted` |
| ~0.3 мягкий primary-круг (empty state) | `SdsFill.soft` |

---

## Стекло и hero

`SdsGlass.blurSigma`, `SdsGlass.heroOverlay`, `SdsGlass.statFill`, … — см. `visual_tokens.dart`.

---

## Особые случаи

- **`Color(category.colorValue).withValues(alpha: …)`** — динамический цвет категории; альфу по возможности свести к **`SdsStroke` / `SdsFill`** там, где смысл «обводка / заливка», а не уникальный оттенок.
- **`.withValues(alpha: 0)`** у `surface` (прозрачный фон под скроллом) — допустим временный паттерн; при `--token-strict` линтер ругается — вынести в хелпер в `ui_components` или локальный `// sss-ui-audit-ignore` с причиной.
