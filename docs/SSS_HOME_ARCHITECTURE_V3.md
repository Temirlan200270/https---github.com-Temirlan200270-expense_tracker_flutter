# SSS Home Architecture v3 — Blueprint

**Цель:** масштабируемая архитектура Home-экрана, которая не становится God-class через 2–3 итерации. Применима как шаблон для Analytics, Budgets, Debts.

---

## 0. Текущее состояние (после v3 decomposition)

```text
packages/app/lib/src/home/
├── home_page.dart                (~390 строк) — ConsumerWidget, decision-driven scaffold
├── home_decision_engine.dart     — HomeDecisionEngine + HomeConsistencyRules (центральный координатор)
├── home_decision.dart            — HomeDecision + HomeConsistencyFlags (единый выход engine)
├── home_event.dart               — HomeEventKind enum (семантические события)
├── home_transition_log.dart      — StateTransitionRecord + ring buffer (observability)
├── home_screen_phase.dart        — resolveHomeScreenPhase() — SSS §2.1
├── home_ftue_state.dart          — FtueStep enum + HomeFtueState + HomeFtueNotifier (persistence)
├── home_layout_shell.dart        — spacing tokens + CustomScrollView каркас
├── home_wallet_shell.dart        — hero card factory (l10n) + WalletHeader
├── home_loaded_hero_block.dart   — hero intelligence: insight, feedback, tone, gradient
├── home_feed_card.dart           — feed карточка + swipe + context menu
├── home_feed_tile_model.dart     — ExpenseTileModel (presentation model)
├── home_feed_provider.dart       — homeFeedTilesProvider (1 подписка вместо N)
├── home_advice_banner.dart       — карточка совета / инсайта
├── home_quick_action_grid.dart   — сетка 2×2 (расход, доход, импорт, категории)
├── home_ftue_steps.dart          — 3 шага onboarding (FTUE-state-aware)
├── home_more_sheet.dart          — bottom sheet «быстрые переходы» + HomeSheetAction
├── home_walkthrough_overlay.dart — walkthrough overlay
├── home_walkthrough_providers.dart
├── home_hero_insight_notifier.dart — стабилизация инсайта (таймеры, feedback)
├── home_hero_resolved_insight.dart — resolved insight state
├── home_ux_insight_logic.dart    — бизнес-логика выбора инсайта
├── home_decision_hero_helper.dart
├── home_insight_identity.dart    — fingerprint инсайта
├── ux_decision_mapper.dart       — маппинг snapshot → UxDecisionView
├── wallet_hero_tone.dart         — градиент / иконка по тону
└── budget_hero_rate_limit_store.dart
```

### Принцип: «1 файл = 1 ответственность, ≤ 300 строк»

Если файл растёт > 350 строк — декомпозиция; если < 50 — объединить с соседним.

---

## 1. Layered Composition Model

```text
┌──────────────────────────────────────────────┐
│  HomeDecisionEngine (AutoDisposeNotifier)     │  ← единый координатор
│  ├── watches: expenses, financial, ftue,      │
│  │           walkthrough                      │
│  ├── resolveHomeScreenPhase()                │  ← data → phase
│  ├── HomeConsistencyRules (6 правил)          │  ← guards / invariants
│  ├── auto-advance FTUE                       │
│  └── → HomeDecision (единый выход)            │
│        ├── phase: UiScreenPhase              │
│        ├── ftue: HomeFtueState               │
│        ├── showWalkthrough: bool             │
│        └── flags: HomeConsistencyFlags       │
├──────────────────────────────────────────────┤
│  HomePage (ConsumerWidget)                   │  ← тонкая оболочка
│  └── ref.watch(homeDecisionProvider)          │  ← ОДИН provider
│  └── _buildBodyForPhase(decision)            │  ← switch по phase
│       ├── _loadingShell                      │
│       ├── _expensesError                     │
│       ├── _emptyLayout                       │  → HomeFtueSteps, PrimaryActionButton
│       └── _nonEmptyLayout                    │  → HomeLoadedHeroBlock, HomeFeedCard
├──────────────────────────────────────────────┤
│  HomeTransitionLog (ring buffer, 64 записи)   │  ← observability layer
│  └── StateTransitionRecord { trigger, from,   │
│       to, rule, detail, timestamp }           │
├──────────────────────────────────────────────┤
│  HomeLoadedHeroBlock (ConsumerStatefulWidget) │  ← insight intelligence layer
├──────────────────────────────────────────────┤
│  HomeFeedCard (ConsumerStatefulWidget)        │  ← card + swipe + context menu
├──────────────────────────────────────────────┤
│  HomeLayoutShell (StatelessWidget)            │  ← scroll structure only
└──────────────────────────────────────────────┘
```

**HomePage** не решает — он рендерит. **DecisionEngine** решает — он не рендерит. Разделение concerns абсолютное.

---

## 2. Следующие шаги (roadmap)

### 2.1 Presentation Model для Feed — DONE

Реализовано:

- `home_feed_tile_model.dart` — `ExpenseTileModel` + `mapExpenseToTile()` + `resolveIcon/IconBackground/IconForeground`
- `home_feed_provider.dart` — `homeFeedTilesProvider` (одна подписка на expenses + categories)
- `HomeFeedCard` принимает `ExpenseTileModel` — **нет `ref.watch(categoriesStreamProvider)` внутри карточки**

### 2.2 FTUE State Machine — DONE

Реализовано:

- `home_ftue_state.dart` — `FtueStep` enum (welcome → firstExpense → insightSeen → completed) + `HomeFtueState` + `HomeFtueNotifier` (SharedPreferences persistence)
- `home_ftue_steps.dart` — визуальная прогрессия шагов (completed / active / pending)
- Auto-advance логика перенесена в Decision Engine (Rule 5, Rule 6)

### 2.2b Unified Decision Engine — DONE

Реализовано:

- `home_decision_engine.dart` — `HomeDecisionEngine` (единый Notifier, watches ALL inputs, outputs ONE `HomeDecision`)
- `home_decision.dart` — `HomeDecision` + `HomeConsistencyFlags`
- `home_event.dart` — `HomeEventKind` enum (семантические события)
- `home_transition_log.dart` — `StateTransitionRecord` + ring buffer (observability)
- 6 именованных consistency rules в `HomeConsistencyRules` (pure functions, testable)
- `HomePage.build()` подписывается только на `homeDecisionProvider` — не принимает решения

### 2.3 Масштабирование паттерна на другие экраны

Тот же подход:

```text
AnalyticsPage
  └── resolveAnalyticsScreenPhase(...)
  └── switch (phase)
       ├── AnalyticsLoadingShell
       ├── AnalyticsErrorState
       ├── AnalyticsEmptyState
       └── AnalyticsReadyLayout
            ├── AnalyticsSnapshotHero
            ├── AnalyticsCategoryBreakdown
            └── AnalyticsTrendChart
```

Каждый экран: **1 phase resolver, 1 thin page, N extracted виджетов**.

### 2.4 Feed Card → Shared Component

`HomeFeedCard` ≈ `ExpensesListTile` в `features_expenses`. Унифицировать в один `ExpenseTileCard` (ui_components или features_expenses), параметризованный `ExpenseTileModel`.

### 2.5 Hero Block → Reusable Decision Surface

`HomeLoadedHeroBlock` содержит insight logic, которая частично дублируется в Analytics snapshot. Выделить `DecisionSurface` — виджет, который принимает `UxDecisionView` + `NumberFormat` и рендерит hero с feedback.

---

## 3. Анти-паттерны (governor)

| Запрещено | Почему |
|-----------|--------|
| `ref.watch(provider)` внутри карточки списка | N подписок вместо одной; заменить Presentation Model |
| Более 1 `showModalBottomSheet` в одном файле | Каждый sheet = отдельный файл |
| `context.push` и `context.go` в одном виджете без комментария | Путаница shell vs modal; документировать или вынести в навигационный helper |
| Файл > 350 строк | Декомпозиция |
| `dynamic` или `as` кастинг extras маршрута | Типизированные extras (record или class) |

---

## 4. Тестирование (target)

| Слой | Тест |
|------|------|
| `HomeConsistencyRules` | Unit: все 6 правил — pure functions, легко тестировать |
| `HomeDecisionEngine` | Unit: комбинации inputs → decision + flags + transitions |
| `HomeTransitionLog` | Unit: ring buffer, capacity, forTrigger, guarded |
| `resolveHomeScreenPhase` | Unit: все комбинации AsyncValue → phase |
| `ExpenseTileModel` mapper | Unit: category lookup, fallback title |
| `HomeFtueNotifier` | Unit: persistence, advanceTo monotonic, markFirstExpense |
| `HomeLoadedHeroBlock` | Widget test: tone → gradient, feedback tap |
| `HomeFeedCard` | Widget test: swipe dismiss, context menu |
| `HomePage` | Integration: decision → correct layout |

---

## 5. Связанные документы

| Артефакт | Путь |
|----------|------|
| SSS UI System v2 | `docs/SSS_UI_SYSTEM_V2.md` |
| Behavior Contract | `docs/SSS_BEHAVIOR_CONTRACT_V1.md` |
| Design System | `DESIGN_SYSTEM.md` |
| Architecture | `ARCHITECTURE.md` |
| UiScreenPhase enum | `packages/shared_models/lib/src/ui_screen_phase.dart` |
| Phase resolver | `packages/app/lib/src/home/home_screen_phase.dart` |
| Decision Engine | `packages/app/lib/src/home/home_decision_engine.dart` |
| Decision model | `packages/app/lib/src/home/home_decision.dart` |
| Transition log | `packages/app/lib/src/home/home_transition_log.dart` |
| FTUE State Machine | `packages/app/lib/src/home/home_ftue_state.dart` |
| Presentation Layer Standard | `docs/SSS_PRESENTATION_LAYER_V1.md` |
