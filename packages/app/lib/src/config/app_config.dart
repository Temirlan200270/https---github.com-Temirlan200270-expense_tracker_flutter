/// Конфигурация приложения
///
/// Для добавления API ключа создай файл `.env` в корне проекта
/// и добавь туда: CURRENCY_API_KEY=твой_ключ
///
/// Или установи переменную окружения: CURRENCY_API_KEY=твой_ключ
class AppConfig {
  // API ключ для валютного API
  // Можно получить на exchangerate-api.com, fixer.io или другом сервисе
  static String? get currencyApiKey {
    // Сначала проверяем переменную окружения
    const envKey = String.fromEnvironment('CURRENCY_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }

    // Если нет переменной окружения, можно использовать дефолтное значение
    // ВАЖНО: Не коммитьте реальные ключи в репозиторий!
    // Для продакшена используйте переменные окружения или secure storage
    return 'c6be39439deed8b6293d9ca7'; // или 'твой_ключ_здесь' для разработки
  }

  // Базовый URL API валют
  static String get currencyApiBaseUrl {
    // Если используется API с ключом, можно изменить URL
    return 'https://api.exchangerate-api.com/v4/latest';
  }

  // Альтернативные API (примеры):
  // Fixer.io: 'https://api.fixer.io/latest'
  // ExchangeRate-API (платный): 'https://v6.exchangerate-api.com/v6/YOUR_API_KEY/latest'

  // API ключ для Gemini API для OCR
  // Получить можно на https://aistudio.google.com/app/apikey
  // Ключ хранится в SharedPreferences через провайдер geminiApiKeyProvider
  static String? get geminiApiKey {
    // Сначала проверяем переменную окружения (для разработки)
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    // ВАЖНО: Для мобильного приложения ключ должен быть установлен через UI в настройках
    return null;
  }

  // Базовый URL Gemini API
  static String get geminiApiBaseUrl {
    return 'https://generativelanguage.googleapis.com/v1beta';
  }
}
