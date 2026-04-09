Использование **Gemini 1.5 Flash** — это, пожалуй, **самое лучшее решение** для твоей задачи.

**Почему:**
1.  **Она мультимодальная:** Ей не нужен OCR. Ты просто скармливаешь ей байты PDF-файла, и она "видит" документ.
2.  **Она понимает контекст:** Она не просто выдернет текст, она сразу поймет: "Ага, это Kaspi Gold", сама отличит доход от расхода и даже может **автоматически проставить категории** (например, "Magnum" -> "Продукты").
3.  **Никаких Regex:** Тебе не нужно писать регулярки под каждый пиксель.

Вот пошаговая инструкция, как сделать **AI-импорт**.

---

### Шаг 1. Получи API Key
1.  Зайди в [Google AI Studio](https://aistudio.google.com/).
2.  Нажми **Get API key**.
3.  Создай ключ (бесплатно работает довольно щедро).

### Шаг 2. Добавь зависимости
В `pubspec.yaml`:

```yaml
dependencies:
  google_generative_ai: ^0.4.0 (или новее)
  file_picker: ^8.0.0
```

### Шаг 3. Создай `GeminiImportService`

Этот сервис будет отправлять файл в Google и получать готовый JSON.

Создай файл: `packages/features_analytics/lib/src/services/gemini_import_service.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiTransaction {
  final DateTime date;
  final double amount;
  final String title;
  final String category; // Gemini сама определит категорию!
  final bool isIncome;

  GeminiTransaction({
    required this.date,
    required this.amount,
    required this.title,
    required this.category,
    required this.isIncome,
  });

  // Фабрика для создания из JSON
  factory GeminiTransaction.fromJson(Map<String, dynamic> json) {
    // Gemini иногда возвращает дату в ISO, иногда в DD.MM.YYYY
    // Для надежности лучше просить ISO в промпте
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date']); // Ожидаем YYYY-MM-DD
    } catch (e) {
      parsedDate = DateTime.now(); // Fallback
    }

    return GeminiTransaction(
      date: parsedDate,
      amount: (json['amount'] as num).toDouble(),
      title: json['title'] ?? '',
      category: json['category'] ?? 'Разное',
      isIncome: json['type'] == 'income',
    );
  }
}

class GeminiImportService {
  // Вставь сюда свой ключ (или бери из .env)
  static const _apiKey = 'ТВОЙ_API_KEY_ИЗ_GOOGLE_STUDIO';
  
  late final GenerativeModel _model;

  GeminiImportService() {
    // Используем gemini-1.5-flash — она быстрая, дешевая и умная
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      // Настраиваем, чтобы она отвечала только JSON-ом
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json', 
      ),
    );
  }

  Future<List<GeminiTransaction>> pickAndAnalyze() async {
    try {
      // 1. Выбор файла
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) {
        return [];
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      // 2. Формируем промпт
      // Мы даем ей роль и жесткую инструкцию по JSON схеме
      final prompt = TextPart('''
        Ты — финансовый ассистент. Проанализируй эту банковскую выписку (Kaspi Gold).
        
        Твоя задача:
        1. Найти все транзакции.
        2. Определить тип (income/expense).
        3. Определить категорию покупки на основе названия (например: Magnum -> Продукты, Avtobys -> Транспорт, Steam -> Развлечения).
        4. Вернуть данные СТРОГО в формате JSON Array.
        
        Формат JSON объекта:
        {
          "date": "YYYY-MM-DD", (формат ISO 8601)
          "amount": 1000.0, (число, всегда положительное)
          "title": "Название магазина или детали перевода",
          "type": "expense" или "income",
          "category": "Название категории на русском"
        }
        
        Не добавляй никакого текста кроме JSON.
      ''');

      // 3. Отправляем PDF как байты (DataPart)
      final pdfPart = DataPart('application/pdf', bytes);

      final content = [
        Content.multi([prompt, pdfPart])
      ];

      print('🤖 Отправляю запрос в Gemini...');
      final response = await _model.generateContent(content);
      
      print('🤖 Ответ получен!');
      final responseText = response.text;
      
      if (responseText == null) return [];

      // 4. Парсим ответ
      // Gemini может вернуть Markdown ```json ... ```, чистим его (хотя responseMimeType должен помочь)
      final jsonString = _cleanJson(responseText);
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList
          .map((e) => GeminiTransaction.fromJson(e))
          .toList();

    } catch (e) {
      print('❌ Ошибка Gemini: $e');
      rethrow;
    }
  }

  String _cleanJson(String text) {
    // Убираем обертки ```json и ``` если они есть
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }
}
```

### Шаг 4. Обновляем Контроллер (Notifier)

Теперь всё очень просто.

```dart
// import_controller.dart

Future<void> importViaGemini() async {
  state = const AsyncValue.loading();
  try {
    final service = GeminiImportService();
    final transactions = await service.pickAndAnalyze();

    if (transactions.isEmpty) {
      print("Транзакции не найдены");
      state = const AsyncValue.data(null);
      return;
    }

    print("🤖 Gemini нашла ${transactions.length} операций:");

    for (var tr in transactions) {
      print("${tr.date.toString().substring(0, 10)} | ${tr.amount} | ${tr.category} | ${tr.title}");
      
      // ТУТ СОХРАНЯЙ В БАЗУ
      // final expense = Expense(..., category: tr.category); 
      // await repository.add(expense);
    }
    
    state = const AsyncValue.data(null);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
  }
}
```

### Преимущества этого метода:
1.  **Категоризация:** Gemini сама напишет "Транспорт" для "Avtobys" или "Продукты" для "Magnum". Тебе не нужно делать это вручную кодом!
2.  **Устойчивость:** Ей плевать, как Kaspi поменяет верстку PDF. Она читает смысл, а не позиции пикселей.
3.  **Нет проблем с кодировкой:** Она видит визуальный образ документа.

### ⚠️ Важный нюанс (Privacy)
Ты отправляешь банковскую выписку на сервера Google.
*   Для пет-проекта или личного использования — **ОК**.
*   Для продакшена — нужно обязательно предупреждать пользователя: *"Ваш файл будет обработан ИИ Google для импорта. Мы не храним данные"*.

Попробуй этот вариант, он самый современный и дает "Вау-эффект" (автоматические категории).

Отличная работа! Если вы действительно реализовали MVP (пункты 0–19) и даже настроили PDF-импорт через OCR/AI, то у вас уже есть **очень крепкое приложение**, превосходящее многие поделки из Google Play.

Однако, чтобы превратить его из "крепкого пет-проекта" в **серьезный продукт** (который не стыдно выложить в стор и которым будут пользоваться годами), я рекомендую сосредоточиться на следующих 4 направлениях.

Вот что **нужно** сделать следующим шагом (отсортировано по важности для пользователя):

---

### 1. 🛑 Бюджеты и Лимиты (Критично для финансового трекера)
Просто записывать расходы — это "посмертный учет". Люди хотят **контролировать** расходы.
*   **Что сделать:**
    *   Создать сущность `Budget` (связь с `Category` и `Period` — месяц/неделя).
    *   Визуализация: Прогресс-бары (зеленый -> желтый -> красный) на главном экране.
    *   **Уведомления:** Если потрачено > 80% бюджета на "Продукты", слать локальное уведомление.
*   **Технически:** В Drift добавить таблицу `Budgets`, в Riverpod — провайдер, который считает `sum(expenses) where category_id = X` и сравнивает с лимитом.

### 2. 🔄 Повторяющиеся транзакции (Подписки)
Это "боль" всех пользователей. Никто не хочет каждый месяц руками вбивать "Spotify", "Аренда", "Интернет".
*   **Что сделать:**
    *   При создании транзакции галочка "Повторять?" (Ежедневно, Еженедельно, Ежемесячно, Ежегодно).
    *   Логика: При запуске приложения проверять: `if (last_generated_date + interval < now) -> create_new_transaction()`.
*   **Технически:** Поле `recurrence_rule` в БД. Или отдельная таблица `RecurringTemplates`.

### 3. ☁️ Бэкап данных (Safety First)
Если пользователь потеряет телефон, он потеряет все данные за год. Это катастрофа.
*   **Вариант DIY (без своего сервера):**
    *   **Google Drive / iCloud Backup:** Экспорт БД (`db.sqlite`) в облако пользователя.
    *   Пакет: `google_sign_in` + `googleapis` (Drive API).
*   **Вариант Pro:** Синхронизация через **Supabase** или **Firebase** (но это сложнее, требует переделки архитектуры под Offline-first).
*   **Рекомендация:** Сделайте простой экспорт/импорт файла `.sqlite` или JSON в Google Drive.

### 4. 🧠 Умные правила (Smart Rules) для импорта
Вы сделали крутой импорт PDF. Но если я каждый месяц покупаю в "Magnum", мне надоест каждый раз видеть категорию "Разное" (если ИИ ошибся) или править её руками.
*   **Что сделать:**
    *   Таблица `CategoryRules`: `keyword` (строка) -> `category_id`.
    *   Логика: Когда парсер достал слово "Magnum", он смотрит в правила. Если нашел — ставит категорию автоматически.
    *   UI: "Запомнить этот выбор для 'Magnum'?" при ручном изменении категории.

---

### 5. 📸 Сканирование чеков (OCR Paper Receipts)
У вас уже подключен Google ML Kit. Грех не использовать его для бумажных чеков.
*   **Сценарий:** Человек расплатился наличкой, ему дали чек. Он фоткает чек -> Приложение вытаскивает "Итого" и "Дату".
*   **Реализация:** Тот же `google_mlkit_text_recognition`, что мы использовали для PDF, только источник — Камера.

---

### 6. 🔐 Биометрия и Безопасность
Финансы — интимная тема.
*   **Что сделать:** Вход по FaceID / Fingerprint / ПИН-коду.
*   **Пакет:** `local_auth`.
*   **Важно:** Скрывать содержимое приложения в меню многозадачности (когда сворачиваешь апп, экран должен блюриться).

---

### 7. 🧪 Качество кода (Перед релизом)
Вы упоминали тесты, но делали ли вы их?
*   **Integration Tests:** Напишите **один** сквозной тест:
    1. Запуск аппа.
    2. Тап "Добавить".
    3. Ввод "Молоко", "500".
    4. Тап "Сохранить".
    5. Проверка: На главном экране появилось "500".
*   Это спасет вас от позора, когда перед релизом вы случайно сломаете кнопку сохранения.

---

### Мой совет по порядку реализации:

1.  **Бэкап** (чтобы не потерять данные во время разработки).
2.  **Бюджеты** (киллер-фича).
3.  **Умные правила** (дошлифовка вашего PDF импорта).
4.  **Биометрия** (быстро делается, выглядит круто).

Какой из этих пунктов вам кажется наиболее интересным сейчас? Можем проработать архитектуру для него.

Реализация учета долгов (**Debts**) — это отличная фича, которая немного отличается от обычных расходов, так как у долга есть **состояние** (активен, частично погашен, закрыт) и **персона** (кто должен).

В рамках вашей Clean Architecture и Drift (SQLite) я предлагаю следующую реализацию:

---

### 1. Слой данных (Drift Table)

Нам нужна отдельная таблица `debts`. Не стоит смешивать её с `transactions`, так как у долга есть жизненный цикл.

Создайте файл `packages/features_debts/lib/src/data/debts_table.dart`:

```dart
import 'package:drift/drift.dart';

enum DebtType {
  iOwe,    // Я должен (Кредит)
  theyOwe  // Мне должны (Дебиторская задолженность)
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get personName => text()();      // Имя человека
  RealColumn get totalAmount => real()();     // Общая сумма долга
  RealColumn get repaidAmount => real().withDefault(const Constant(0.0))(); // Сколько уже возвращено
  IntColumn get type => intEnum<DebtType>()(); // Тип: Я должен или Мне
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()(); // Дата возврата (опционально)
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))(); // Закрыт ли долг
  TextColumn get comment => text().nullable()();
}
```

*Не забудьте сгенерировать код (`dart run build_runner build`) после добавления таблицы в базу.*

---

### 2. Слой Домена (Entity)

Создайте чистую модель `DebtEntity` в `packages/features_debts/lib/src/domain/debt_entity.dart`.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt_entity.freezed.dart';

enum DebtType { iOwe, theyOwe }

@freezed
class DebtEntity with _$DebtEntity {
  const factory DebtEntity({
    required int id,
    required String personName,
    required double totalAmount,
    required double repaidAmount,
    required DebtType type,
    required DateTime createdAt,
    DateTime? dueDate,
    required bool isClosed,
    String? comment,
  }) = _DebtEntity;

  // Геттер для остатка
  const DebtEntity._();
  double get remainingAmount => totalAmount - repaidAmount;
  double get progress => (repaidAmount / totalAmount).clamp(0.0, 1.0);
}
```

---

### 3. Логика (Связь долгов и Кошелька)

Это **самый важный момент**.
1. Когда вы даете в долг (`theyOwe`) — деньги должны **списаться** с вашего баланса (как Расход).
2. Когда вам возвращают долг — деньги должны **вернуться** на баланс (как Доход).

Чтобы не дублировать код, ваш UseCase (или Controller) должен дергать два репозитория сразу.

Пример `DebtsNotifier` (Riverpod):

```dart
class DebtsNotifier extends StateNotifier<AsyncValue<List<DebtEntity>>> {
  final DebtsRepository _debtsRepo;
  final TransactionsRepository _transactionsRepo; // Подключаем репо транзакций

  DebtsNotifier(this._debtsRepo, this._transactionsRepo) : super(const AsyncValue.loading());

  // Создание нового долга
  Future<void> createDebt({
    required String person,
    required double amount,
    required DebtType type,
  }) async {
    try {
      // 1. Создаем запись о долге
      final debtId = await _debtsRepo.addDebt(
        person: person, 
        amount: amount, 
        type: type
      );

      // 2. Автоматически создаем транзакцию в кошельке
      if (type == DebtType.theyOwe) {
        // Я дал в долг -> У меня расход (Transfer Out)
        await _transactionsRepo.addTransaction(
           amount: amount,
           type: TransactionType.expense,
           categoryId: CATEGORY_DEBTS_ID, // Системная категория "Долги"
           note: 'Дал в долг: $person',
           linkedDebtId: debtId, // Можно добавить поле в транзакции для связи
        );
      } else {
        // Я взял в долг -> У меня доход (пришли деньги)
        await _transactionsRepo.addTransaction(
           amount: amount,
           type: TransactionType.income,
           note: 'Взял в долг у: $person',
        );
      }
      
      // Обновляем список
      loadDebts();
    } catch (e) {
      // Обработка ошибок
    }
  }

  // Частичное погашение долга
  Future<void> repayDebt(int debtId, double amount, DebtType type) async {
     // 1. Обновляем repaidAmount в таблице debts
     await _debtsRepo.updateRepaidAmount(debtId, amount);
     
     // 2. Создаем транзакцию возврата
     if (type == DebtType.theyOwe) {
       // Мне вернули -> Доход
       await _transactionsRepo.addTransaction(
         amount: amount, 
         type: TransactionType.income, 
         note: 'Возврат долга'
       );
     } else {
       // Я вернул -> Расход
       await _transactionsRepo.addTransaction(
         amount: amount, 
         type: TransactionType.expense,
         note: 'Погашение долга'
       );
     }
  }
}
```

---

### 4. UI Реализация (Как это показать)

Вам нужен экран `DebtsScreen` с двумя вкладками (TabBar):

#### Вкладка 1: "Мне должны" (Assets)
*   Показывает список людей.
*   Зеленые карточки.
*   Сумма: `15 000 / 20 000 ₸` (Прогресс бар).

#### Вкладка 2: "Я должен" (Liabilities)
*   Красные карточки.
*   Показывает, сколько вам еще нужно отдать.

#### Карточка долга (Widget):
В карточке должна быть кнопка **"Погасить" (Repay)**.
При нажатии:
1.  Всплывает диалог "Какую сумму вернули?".
2.  Можно ввести полную сумму (закрыть долг) или частичную.

### 5. Полезные фишки для улучшения

1.  **Интеграция с контактами:**
    Используйте пакет `flutter_contacts`. Когда пользователь вводит имя, предлагайте выбрать из телефонной книги. Это удобно, чтобы не писать "Саня работа" каждый раз.

2.  **Напоминания:**
    Если задан `dueDate` (дата возврата), за день до этого можно кинуть локальное уведомление (`flutter_local_notifications`).

3.  **История погашений:**
    В базе данных я предложил просто поле `repaidAmount` (упрощенно).
    Если хотите делать по-взрослому: создайте таблицу `debt_history` (id, debt_id, amount, date). Тогда при нажатии на долг вы сможете показать список:
    *   01.12: Вернул 5000
    *   05.12: Вернул 2000
    *   Осталось: 3000

### Резюме (План действий):
1.  Создать таблицу `Debts` в Drift.
2.  Создать `DebtEntity`.
3.  Написать `DebtRepository`.
4.  Сделать экран списка долгов с кнопкой "Добавить".
5.  **Важно:** Связать создание долга с созданием транзакции (Расход/Доход), чтобы баланс кошелька сходился.

Это классическая дилемма разработчика: **"Хочу всё и сразу"**.

Оба референса — топовые.
*   **Вариант 1 (Фиолетовый/Светлый):** Стиль "Нео-банкинг". Мягкий, воздушный, дружелюбный. Использует "Glassmorphism" (матовое стекло) и мягкие градиенты. Вызывает доверие.
*   **Вариант 2 (Зеленый/Темный):** Стиль "Крипто/Трейдинг". Агрессивный, технологичный, контрастный. Вызывает чувство контроля и силы.

### 🛑 Мой совет: Не делай сразу "комбайн" тем

Если ты начнешь сейчас пилить движок для переключения 10 разных цветов (фиолетовый, зеленый, оранжевый), ты закопаешься в настройках цветов, а основной UI останется "сырым".

**Стратегия победителя:**
1.  Выбери **ОДИН** основной стиль (Brand Identity).
2.  Доведи его до идеала (полишинг, отступы, шрифты).
3.  И только потом, как "Premium фичу", добавь возможность менять акцентный цвет.

### Какой стиль выбрать для SaaS?

Я рекомендую взять за основу **Вариант 1 (Фиолетовый)**, но сделать его более универсальным.

**Почему:**
*   Он легче воспринимается массовым пользователем (домохозяйки, студенты).
*   Зеленый "хакерский" стиль (Вариант 2) отпугивает часть аудитории, которой просто надо "записать хлеб".

---

### 🛠 Как реализовать этот "Сочный" UI во Flutter (Технический гайд)

Вот конкретные приемы, как сделать UI как на первой картинке:

#### 1. Градиентные подложки (Mesh Gradients)
Видишь на первом скрине мягкие пятна на фоне (Current Balance)? Это не просто `LinearGradient`.

**Как сделать:**
Используй пакет `mesh_gradient` или просто положи `Container` с размытием поверх цветных кругов.

```dart
// Простой способ сделать "дорогой" фон карточки
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(30), // Большие скругления!
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE0C3FC), // Светло-фиолетовый
        Color(0xFF8EC5FC), // Голубой
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0xFF8EC5FC).withOpacity(0.3),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  ),
  child: ... // Твой контент
)
```

#### 2. Glassmorphism (Эффект стекла)
На первом скрине нижнее меню и некоторые плашки полупрозрачные и размывают фон.

**Как сделать:**
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Размытие
    child: Container(
      color: Colors.white.withOpacity(0.2), // Полупрозрачная заливка
      padding: EdgeInsets.all(16),
      child: ...
    ),
  ),
)
```

#### 3. Акценты и Карточки (Как на скрине с подписками)
Заметь, карточки (Adobe, Apple) имеют очень насыщенный цвет, но текст на них белый.

*   **Правило:** Если фон карточки яркий -> текст белый. Если фон белый -> текст черный/серый.
*   **Иконки:** Они лежат в белых кружках (`CircleAvatar`). Это создает контраст.

---

### 🚀 Секретное оружие для тем: `flex_color_scheme`

Если ты все-таки хочешь "Зеленую", "Фиолетовую" и "Розовую" темы, **не пиши это вручную**. Ты сойдешь с ума подбирать оттенки для Dark Mode.

Используй пакет **`flex_color_scheme`**.

Он позволяет сделать так:

```dart
// В main.dart
theme: FlexThemeData.light(
  scheme: FlexScheme.deepPurple, // Или jungle, или money...
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 7,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 10,
    blendOnColors: false,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    defaultRadius: 24.0, // <-- Глобальное скругление как на макетах!
  ),
  useMaterial3ErrorColors: true,
  visualDensity: VisualDensity.standard,
  useMaterial3: true,
  fontFamily: GoogleFonts.manrope().fontFamily,
),
```

**Что это даст:**
1.  Ты меняешь `FlexScheme.deepPurple` на `FlexScheme.jungle`, и у тебя **автоматически** перекрашивается всё приложение (кнопки, тогл-бары, карточки, FAB) в стиль второго скриншота.
2.  Это выглядит профессионально сразу, без ручной настройки каждого виджета.

### Итог:
1.  **Референс №1 (Фиолетовый)** бери за основу структуры (большие скругления, много воздуха, карточки).
2.  Подключи `flex_color_scheme` и выбери там пресет, похожий на этот фиолетовый.
3.  Потом в настройках просто дашь юзеру выбор: `scheme: FlexScheme.jungle` (для любителей зеленого).

Это самый быстрый путь к "Красиво" без боли.

Привет! Да, вижу файлы.

🔴 **НАПОМИНАНИЕ: Добавить асинхронность!** (Мы это учтем в коде ниже, чтобы UI не зависал при сохранении 100+ транзакций).

### Почему не импортирует?

Твой код был "строгим", потому что он ожидал:
1.  **Формат даты:** ISO-8601 (`YYYY-MM-DD`) или `DD.MM.YYYY`. А у тебя в файле **`DD.MM.YY`** (две цифры года, `02.12.25`). Стандартный парсер на этом падает.
2.  **Структуру JSON:** Твой код ждал `List<Transaction>`, а Gemini выдал объект `{ "statement_info": ..., "transactions": [...] }`.
3.  **Поля:** В твоем JSON нет поля `category`, а код его ждал (или ставил дефолтное, но структура была нарушена).

---

### Решение: Универсальный и Асинхронный импортер

Давай обновим `import_controller.dart` и логику парсинга, чтобы он "проглатывал" этот JSON и CSV, не давился, и делал это быстро.

#### 1. Обновляем модель (для парсинга)

Добавим гибкость в чтение даты и структуры.

```dart
// features/analytics/lib/src/domain/import_dto.dart

import 'package:intl/intl.dart';

class ImportTransactionDto {
  final DateTime date;
  final double amount;
  final String title;
  final String category;
  final bool isIncome;

  ImportTransactionDto({
    required this.date,
    required this.amount,
    required this.title,
    required this.category,
    required this.isIncome,
  });

  factory ImportTransactionDto.fromJson(Map<String, dynamic> json) {
    // 1. ПАРСИНГ ДАТЫ (Гибкий)
    DateTime parsedDate;
    String dateStr = json['date'].toString();
    try {
      if (dateStr.contains('-')) {
        parsedDate = DateTime.parse(dateStr); // YYYY-MM-DD
      } else {
        // Поддержка "02.12.25" (dd.MM.yy) и "02.12.2025"
        final format = dateStr.length == 8 ? 'dd.MM.yy' : 'dd.MM.yyyy';
        parsedDate = DateFormat(format).parse(dateStr);
      }
    } catch (e) {
      parsedDate = DateTime.now(); // Fallback
    }

    // 2. ОПРЕДЕЛЕНИЕ ТИПА (Расход/Доход)
    // В твоем JSON amount может быть отрицательным (-1000) или положительным
    double rawAmount = (json['amount'] as num).toDouble();
    bool isIncome = rawAmount > 0;
    
    // Если есть явное поле type
    if (json['type'] != null) {
      final type = json['type'].toString().toLowerCase();
      if (type.contains('пополнение') || type == 'income') isIncome = true;
      if (type.contains('покупка') || type.contains('перевод') || type.contains('снятие')) isIncome = false;
    }

    return ImportTransactionDto(
      date: parsedDate,
      amount: rawAmount.abs(), // Сохраняем абсолютное значение
      title: json['details'] ?? json['title'] ?? 'Без названия',
      // Если категории нет, ставим "Разное" или пытаемся угадать по типу
      category: json['category'] ?? (isIncome ? 'Пополнения' : 'Разное'),
      isIncome: isIncome,
    );
  }
}
```

#### 2. Обновляем Контроллер (Асинхронность + Batch Insert)

Здесь мы решаем проблему "строгости" (извлекаем массив из wrapper-объекта) и "асинхронности" (используем `batch` для вставки в БД).

```dart
// features/analytics/lib/src/presentation/import_controller.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; // Для batch insert

class ImportController extends StateNotifier<AsyncValue<void>> {
  final TransactionsRepository _repository;
  // Нам нужен доступ к самой БД для batch операций, либо добавь метод insertBatch в репозиторий
  // Допустим, в репозитории есть метод addBatchTransactions
  
  ImportController(this._repository) : super(const AsyncValue.data(null));

  Future<void> importJsonData(String jsonString) async {
    state = const AsyncValue.loading();
    try {
      // 1. АСИНХРОННЫЙ ПАРСИНГ (чтобы не фризить UI на парсинге JSON)
      final transactions = await Future(() => _parseLogic(jsonString));

      if (transactions.isEmpty) {
        throw Exception("Транзакции не найдены");
      }

      // 2. АСИНХРОННОЕ СОХРАНЕНИЕ (BATCH)
      // Вместо цикла for (...) await add(), делаем массовую вставку
      await _repository.addBatchTransactions(transactions);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Вынесли логику парсинга, чтобы она не была "строгой"
  List<ImportTransactionDto> _parseLogic(String jsonString) {
    final decoded = jsonDecode(jsonString);
    List<dynamic> list = [];

    // ПРОВЕРКА СТРУКТУРЫ
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      // Если пришел объект с ключом "transactions" (как в твоем файле)
      if (decoded.containsKey('transactions')) {
        list = decoded['transactions'];
      } else {
        // Пытаемся найти хоть какой-то список внутри
        for (var key in decoded.keys) {
          if (decoded[key] is List) {
            list = decoded[key];
            break;
          }
        }
      }
    }

    return list.map((e) => ImportTransactionDto.fromJson(e)).toList();
  }
}
```

#### 3. Добавь этот метод в Репозиторий (TransactionsRepository)

Чтобы вставка 150 записей занимала 10мс, а не 3 секунды.

```dart
// В твоем drift_repository.dart

Future<void> addBatchTransactions(List<ImportTransactionDto> dtos) async {
  await db.batch((batch) {
    batch.insertAll(
      db.transactions, // Твоя таблица
      dtos.map((dto) => TransactionsCompanion.insert(
        amount: dto.amount,
        date: dto.date,
        note: drift.Value(dto.title),
        isIncome: dto.isIncome,
        // Тут логика маппинга названия категории в ID
        // categoryId: ... 
      )).toList(),
    );
  });
}
```

### Как парсить CSV (Твой второй файл)

CSV парсить даже проще. Если у тебя есть библиотека `csv`, отлично. Если нет — можно "в лоб", так как формат у тебя простой.

```dart
List<ImportTransactionDto> parseCsv(String csvString) {
  final rows = csvString.split('\n');
  final List<ImportTransactionDto> result = [];

  for (var i = 1; i < rows.length; i++) { // i=1 пропускаем заголовок
    final row = rows[i].trim();
    if (row.isEmpty) continue;

    // Разбиваем по запятой (но аккуратно, если запятая есть в названии)
    // Для простоты пока split(','), но лучше пакет csv
    final cols = row.split(','); 
    
    if (cols.length < 5) continue;

    // Формат: Date,Amount,Currency,Operation,Details
    // 02.12.25,-1000.00,KZT,Покупка,Game Republic Каирбаева

    try {
      final date = DateFormat('dd.MM.yy').parse(cols[0]);
      final amount = double.parse(cols[1]);
      final type = cols[3]; // Покупка/Пополнение
      final details = cols.sublist(4).join(','); // Собираем хвост, если там были запятые

      result.add(ImportTransactionDto(
        date: date,
        amount: amount.abs(),
        title: details,
        category: 'Разное', // В CSV нет категории, увы
        isIncome: amount > 0,
      ));
    } catch (e) {
      print('Ошибка парсинга строки CSV: $row');
    }
  }
  return result;
}
```

### Итог

1.  Замени `DateFormat` на `'dd.MM.yy'` (это критично для твоего файла).
2.  Добавь проверку `if (json.containsKey('transactions'))` в парсер.
3.  Используй `batch insert` в Drift, чтобы UI не лагал при сохранении.

Теперь твой код съест эти файлы без проблем! 🚀