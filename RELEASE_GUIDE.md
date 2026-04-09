# Руководство по релизу Expense Tracker

## 📋 Подготовка к релизу

### 1. Иконка приложения

Для генерации иконок приложения:

1. Создайте папку `assets/icon/`
2. Добавьте файл `icon.png` (1024x1024 px) - основная иконка
3. Добавьте файл `icon_foreground.png` (1024x1024 px) - для адаптивных иконок Android
4. Добавьте в `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.14.2
   ```
5. Запустите:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

### 2. Подпись приложения (Android)

Для релиза в Google Play Store:

1. Создайте keystore:
   ```bash
   keytool -genkey -v -keystore android/keystore/release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias expense_tracker
   ```

2. Создайте файл `android/key.properties`:
   ```properties
   storePassword=ваш_пароль
   keyPassword=ваш_пароль
   keyAlias=expense_tracker
   storeFile=keystore/release.jks
   ```

3. Обновите `android/app/build.gradle.kts`:
   - Раскомментируйте секцию signingConfigs
   - Замените `signingConfig = signingConfigs.getByName("debug")` на `signingConfig = signingConfigs.getByName("release")`

### 3. Сборка

#### APK (для тестирования)
```bash
flutter build apk --release
```
Файл: `build/app/outputs/flutter-apk/app-release.apk`

#### AAB (для Google Play)
```bash
flutter build appbundle --release
```
Файл: `build/app/outputs/bundle/release/app-release.aab`

### 4. Публикация в Google Play

1. Зарегистрируйтесь в [Google Play Console](https://play.google.com/console)
2. Создайте новое приложение
3. Заполните информацию:
   - Название: "Трекер расходов" / "Expense Tracker"
   - Описание: см. ниже
   - Скриншоты
   - Иконка
4. Загрузите AAB файл

## 📝 Описание для магазина

### Краткое описание (80 символов)
**RU:** Отслеживайте расходы, анализируйте траты и контролируйте бюджет
**EN:** Track expenses, analyze spending and control your budget

### Полное описание

**RU:**
```
Трекер расходов - простое и удобное приложение для управления личными финансами.

✨ Основные возможности:
• Добавление доходов и расходов
• Категории с цветовой маркировкой
• Графики и аналитика по тратам
• Фильтрация по дате, категориям и типу
• Экспорт данных в CSV, JSON и PDF
• Импорт выписок из банков
• Поддержка нескольких валют
• Тёмная и светлая темы
• Русский и английский языки

📊 Аналитика:
• Статистика за день, неделю, месяц, год
• Сравнение с предыдущим периодом
• Топ категорий расходов
• Графики динамики

🔒 Приватность:
• Все данные хранятся локально на устройстве
• Никакой регистрации не требуется
• Нет рекламы

Начните контролировать свои финансы уже сегодня!
```

**EN:**
```
Expense Tracker - a simple and convenient app for managing personal finances.

✨ Key Features:
• Add income and expenses
• Color-coded categories
• Charts and spending analytics
• Filter by date, categories, and type
• Export data to CSV, JSON, and PDF
• Import bank statements
• Multi-currency support
• Dark and light themes
• English and Russian languages

📊 Analytics:
• Statistics for day, week, month, year
• Comparison with previous period
• Top spending categories
• Dynamic charts

🔒 Privacy:
• All data stored locally on device
• No registration required
• No ads

Start controlling your finances today!
```

## 🔧 CI/CD

Проект настроен для автоматической сборки через GitHub Actions:

- **Тесты**: Автоматически запускаются при push и pull request
- **APK**: Автоматически собирается и загружается как артефакт
- **AAB**: Собирается при push в main ветку
- **Релиз**: Автоматически создаётся при создании тега версии (v*)

### Создание релиза

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 📁 Структура версий

Версия приложения определяется в `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Где:
- `1.0.0` - versionName (отображается пользователям)
- `+1` - versionCode (должен увеличиваться с каждым релизом)

## ✅ Чеклист перед релизом

- [ ] Обновлена версия в pubspec.yaml
- [ ] Все тесты проходят
- [ ] Иконка приложения обновлена
- [ ] Подпись настроена
- [ ] Описание для магазина готово
- [ ] Скриншоты подготовлены
- [ ] Тестирование на реальном устройстве

