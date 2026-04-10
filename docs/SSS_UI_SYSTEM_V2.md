# SSS UI SYSTEM v2 — Master Plan (поведение + покрытие + контракт)

**Назначение:** слой поверх [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md) (язык и Blueprint) и Execution v1 в коде. Это **операционная система интерфейса**: экраны, состояния во времени, граничные случаи и измеримый контракт пикселей/движения — не замена Blueprint, а его дополнение.

**Оговорка:** документ «полный для разработки и доведения до SSS»; продукт эволюционирует — разделы 1–3 пересматриваются при новых флоу.

---

## 0. Слои SSS (UI + поведение)

```text
1. UI Language       → DESIGN_SYSTEM.md (Blueprint)
2. UI Execution      → layouts, shell’ы, экраны в коде
3. UI State Machine  → что происходит во времени (данные, инсайт, stale)
4. UI Coverage       → карта экранов + матрица edge cases
5. Behavior Contract → SSS_BEHAVIOR_CONTRACT_V1.md (трение, стабильность, один голос)
```

---

## 1. FULL SCREEN MAP (роли и приоритеты)

### 1.1 Core flows

| Flow | Экраны / узлы | Роль |
|------|----------------|------|
| **Home** | Home (Decision), лента, CTA | Один hero, один primary CTA |
| **Home → деталь** | Transaction list → деталь операции (при наличии) | Detail / metadata |
| **Analytics** | Overview, категории, бюджеты, сравнение периодов | Analysis Mode |
| **Import** | Import, review queue, подтверждения bulk | Action Mode |
| **Config** | Settings, бюджеты, категории, recurring, export/import | Навигация из меню Home |

### 1.1.1 Опциональный AI-импорт выписки

Пошаговые промпты и примеры кода для Gemini не хранятся в репозитории (шум и устаревание). При необходимости: [Google AI Studio](https://aistudio.google.com/), пакет `google_generative_ai`, ответ строго в JSON; ключи — только через env / secure storage, не в исходниках. Реализация — в слое импорта (`features_export` или отдельный сервис).

### 1.2 System & intelligence (целевое покрытие)

| Область | Статус в продукте | Примечание |
|---------|-------------------|------------|
| Empty / FTUE | Частично (Home FTUE) | Отдельный onboarding v2 — по продукту |
| Offline / stale | Зафиксировать в state machine | Не только копирайт, а явное UI-состояние |
| Ошибка / partial snapshot | Fallback + retry | См. §3 |
| Intervention / «почему решение» | Roadmap v4+ | Документировать до появления в коде |

**Правило:** мелкие экраны и системные состояния ломают ощущение премиума сильнее, чем Home — приоритет бэклога по §10 DESIGN_SYSTEM + этому документу.

---

## 2. UI STATE MACHINE (глобально)

### 2.1 Состояния экрана (канон)

Каждый экран **в момент времени** укладывается в одно из:

```text
LOADING   → данные ещё не готовы
READY     → есть консистентный снимок для UI
STALE     → показан кэш, фоновое обновление
UPDATING  → явный refresh / sync
ERROR     → нет доверенных данных
EMPTY     → валидное «пусто» (0 операций и т.д.)
PARTIAL   → часть данных недоступна, остальное OK
```

**Интеграция с кодом:** не обязательно один enum на весь апп — но **один доминирующий источник правды на экран** (например `financialSnapshotProvider` на Home) и явный fallback UI для ERROR/PARTIAL.

### 2.2 Жизненный цикл инсайта (логический)

```text
Generated → Ranked → Shown → Viewed → Feedback (или ignore)
         → корректировка confidence / приоритетов → demote / promote
```

### 2.3 Home Hero (логическая машина)

```text
Snapshot → расчёт инсайта → fingerprint / стабильность
       → reveal → окно удержания (min display)
       → окно feedback → отложенный resync при смене данных
```

Детали реализации — в коде (`_HomeLoadedHeroBlock`, провайдеры снимка и feedback).

### 2.4 Петля feedback

Пользователь: useful / not useful / ignore → обновление весов, бюджетного приоритета, rate limits (см. архитектуру feedback в коде).

---

## 3. EDGE CASE MATRIX (UI-поведение)

### 3.1 Данные

| Случай | Ожидаемое UI |
|--------|----------------|
| Нет транзакций | EMPTY: FTUE hero + один CTA |
| Partial sync | PARTIAL/STALE: ненавязчивый индикатор + не противоречить snapshot |
| Конкурирующие сигналы | Один сильный сигнал в hero; остальное в деталь |
| Нет категории | Нейтральный копирайт / без агрессивного инсайта |

### 3.2 Финансы

| Случай | Ожидаемое UI |
|--------|----------------|
| Отрицательный баланс / danger | Тон risk, без лишнего motion |
| Всплеск трат | watch, смягчённый тон |
| Нулевая активность | нейтральная мотивация |
| Over budget | сдвиг состояния, не «крик» |

### 3.3 Система

| Случай | Ожидаемое UI |
|--------|----------------|
| Offline | frozen / явное «данные на дату» |
| Ошибка снимка | ERROR: сообщение + primary CTA (без второго провайдера «цифр») |
| Повреждённые данные | безопасный fallback + support path (по продукту) |

---

## 4. PIXEL & MOTION CONTRACT (привязка к коду)

### 4.1 Spacing (экранный ритм)

Канон для **внешних** отступов экранов и главных секций (расширять только осознанно):

```text
8, 12, 16, 20, 24, 32  (логические единицы, dp)
```

Home: `HomeLayoutSpacing` в `packages/app/lib/src/home/home_layout_shell.dart`.

Микро-интервалы **внутри** компонента (между строками label) допускаются точечно; наружу — только сетка.

### 4.2 Radius (ориентир)

```text
8   — chips / мелкие контролы
12  — иконки-кнопки, вложенные блоки
16  — карточки списка
20  — primary кнопки, крупные карточки
28  — hero / крупные плавающие поверхности
```

### 4.3 Elevation (смысл)

```text
Surface 0 — фон
Surface 1 — списки, лёгкая глубина
Surface 2 — единственный hero на экране Decision Mode
```

### 4.4 Motion — единый источник: `AppMotion`

Файл: `packages/ui_components/lib/src/theme/motion_tokens.dart`.

| Токен | Значение | Назначение |
|-------|----------|------------|
| `fast` | 120 ms | микро-отклик |
| `standard` | 200 ms | блоки, списки |
| `screen` | 280 ms | hero / крупные сдвиги |
| `staggerInterval` | 30 ms | stagger списков |
| `curve` | `easeOutCubic` | по умолчанию |
| `curveReverse` | `easeInCubic` | обратные переходы |

**Интервалы из Master Plan (260–320 ms hero):** `screen = 280 ms` — внутри диапазона; новые длительности добавлять только в `AppMotion`.

**Запрещено:** bounce, elastic, «случайные» кривые в продуктовых анимациях.

---

## 5. Cross-screen consistency

- **Hero / snapshot:** один язык тона и типографики между Wallet hero и блоком снимка на Analytics (разница — наличие CTA на Home).
- **Инсайт:** одинаковые лимиты строк, тон, feedback где применимо.
- **Primary CTA:** один главный на первом экране флоу (исключения — явно в PR).

---

## 6. UI Governor (нельзя нарушать без пометки в PR)

**Запрещено:**

- два равнозначных hero на одном экране Decision Mode;
- график внутри hero;
- несколько primary CTA выше fold без обоснования;
- произвольные hex-цвета в фичах вместо `colorScheme` / токенов темы;
- «рандомные» отступы экрана вне сетки;
- анимации без смысла или конкурирующие за внимание.

**Обязательно:**

- иерархия 1 → 2 → 3 на экране;
- у инсайта — устойчивый идентификатор / fingerprint (где применимо);
- у состояния ERROR — fallback UI;
- motion из `AppMotion` (или эквивалент согласован в PR);
- чеклист DESIGN_SYSTEM §10 для PR целого экрана.

---

## 7. Quality bar (SSS)

- Смысл экрана ≤ ~2.5 с; одно очевидное действие; нет визуального шума.
- Системно: нет дублирующих источников правды для одних и тех же цифр на экране; нет локальных «особых» стилей без причины.

---

## 8. Автоматический аудит (Execution)

Скрипт проверяет **грубые** нарушения governor / motion (эвристики, не замена ревью).

Из корня репозитория:

```bash
dart tool/sss_ui_audit.dart
```

Строгий режим (warnings тоже падают с ненулевым кодом):

```bash
dart tool/sss_ui_audit.dart --strict
```

Подробности правил — комментарий в начале `tool/sss_ui_audit.dart`.

Игнор строки/файла:

```dart
// sss-ui-audit-ignore
```

---

## 9. Связанные артефакты

| Артефакт | Путь |
|----------|------|
| Blueprint | [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md) |
| Behavior Contract | [SSS_BEHAVIOR_CONTRACT_V1.md](SSS_BEHAVIOR_CONTRACT_V1.md) |
| Архитектура | [ARCHITECTURE.md](../ARCHITECTURE.md) |
| Home layout shell | `packages/app/lib/src/home/home_layout_shell.dart` |
| Онбординг / Lock (shell) | `packages/app/lib/src/onboarding/onboarding_page.dart`, `packages/app/lib/src/presentation/lock_screen.dart` |
| Analytics layout / сетка | `packages/features_analytics/lib/src/presentation/layout/analytics_layout_spacing.dart` |
| Analytics Surface 1 | `packages/features_analytics/lib/src/presentation/widgets/analytics_surface_card.dart` |
| Import layout / сетка | `packages/features_export/lib/src/presentation/layout/import_layout_spacing.dart` |
| Import Surface 1 | `packages/features_export/lib/src/presentation/widgets/import_surface_card.dart` |
| Export / Backup / Import review (экраны) | `packages/features_export/lib/src/presentation/pages/` |
| Motion tokens | `packages/ui_components/lib/src/theme/motion_tokens.dart` |
