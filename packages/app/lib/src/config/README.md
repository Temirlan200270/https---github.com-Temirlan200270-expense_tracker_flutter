# Конфигурация API ключей

## Как добавить API ключ для валютного API

### Способ 1: Переменная окружения (рекомендуется)

1. Установи переменную окружения перед запуском:

**Windows (PowerShell):**
```powershell
$env:CURRENCY_API_KEY="твой_ключ_здесь"
flutter run
```

**Windows (CMD):**
```cmd
set CURRENCY_API_KEY=твой_ключ_здесь
flutter run
```

**Linux/macOS:**
```bash
export CURRENCY_API_KEY="твой_ключ_здесь"
flutter run
```

2. Или добавь в файл запуска (например, `run.bat` или `run.sh`)

### Способ 2: Прямое указание в коде (только для разработки)

Открой файл `packages/app/lib/src/config/app_config.dart` и измени:

```dart
static String? get currencyApiKey {
  const envKey = String.fromEnvironment('CURRENCY_API_KEY');
  if (envKey.isNotEmpty) {
    return envKey;
  }
  
  // ВАЖНО: Не коммитьте это в репозиторий!
  return 'твой_ключ_здесь'; // Только для локальной разработки
}
```

### Способ 3: Через .env файл (требует пакет flutter_dotenv)

1. Установи пакет:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Создай файл `.env` в корне проекта:
```
CURRENCY_API_KEY=твой_ключ_здесь
```

3. Добавь `.env` в `.gitignore`

4. Загрузи в `bootstrap.dart`:
```dart
await dotenv.load(fileName: ".env");
```

## Где получить API ключ?

- **exchangerate-api.com** - бесплатный план без ключа, платный с ключом
- **fixer.io** - требуется регистрация и API ключ
- **exchangerate.host** - бесплатный API
- **currencyapi.net** - бесплатный и платный планы

## Безопасность

⚠️ **НИКОГДА не коммитьте API ключи в репозиторий!**

- Используй переменные окружения для продакшена
- Добавь `.env` в `.gitignore`
- Для CI/CD используй секреты (GitHub Secrets, GitLab CI Variables и т.д.)

