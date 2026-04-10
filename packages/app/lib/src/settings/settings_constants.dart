/// Технические идентификаторы настроек (не UI-тексты): API id, коды валют.
abstract final class GeminiModelIds {
  GeminiModelIds._();

  /// Значение по умолчанию в prefs и в UI-подсказке поля ввода.
  static const String defaultId = 'gemini-2.5-flash';

  /// Быстрый выбор в диалоге модели (идентификаторы Google API).
  static const List<String> suggestedIds = <String>[
    'gemini-2.0-flash-exp',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];
}

/// Поддерживаемые коды валюты по умолчанию (ISO 4217).
abstract final class SettingsCurrencyCodes {
  SettingsCurrencyCodes._();

  static const List<String> supported = <String>[
    'KZT',
    'RUB',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CNY',
  ];
}
