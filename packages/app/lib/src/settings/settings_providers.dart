import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_constants.dart';

// Провайдер для SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider должен быть переопределен в bootstrap');
});

// Провайдер для темы
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  final SharedPreferences _prefs;
  static const String _key = 'theme_mode';

  Future<void> _loadThemeMode() async {
    final saved = _prefs.getString(_key);
    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

// Провайдер для языка
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(null) {
    _loadLocale();
  }

  final SharedPreferences _prefs;
  static const String _key = 'locale';

  void _loadLocale() {
    final saved = _prefs.getString(_key);
    if (saved != null) {
      final parts = saved.split('_');
      if (parts.length == 2 && parts[1].isNotEmpty) {
        state = Locale(parts[0], parts[1]);
      } else if (parts.isNotEmpty) {
        state = Locale(parts[0]);
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final key = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await _prefs.setString(_key, key);
  }
}

// Провайдер для валюты по умолчанию
final defaultCurrencyProvider =
    StateNotifierProvider<DefaultCurrencyNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DefaultCurrencyNotifier(prefs);
});

class DefaultCurrencyNotifier extends StateNotifier<String> {
  DefaultCurrencyNotifier(this._prefs) : super('KZT') {
    _loadCurrency();
  }

  final SharedPreferences _prefs;
  static const String _key = 'default_currency';

  void _loadCurrency() {
    final saved = _prefs.getString(_key);
    if (saved != null && saved.length == 3) {
      state = saved;
    }
  }

  Future<void> setCurrency(String currencyCode) async {
    if (currencyCode.length != 3) return;
    state = currencyCode;
    await _prefs.setString(_key, currencyCode);
  }
}

// Провайдер для Gemini API ключа
final geminiApiKeyProvider =
    StateNotifierProvider<GeminiApiKeyNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GeminiApiKeyNotifier(prefs);
});

class GeminiApiKeyNotifier extends StateNotifier<String?> {
  GeminiApiKeyNotifier(this._prefs) : super(null) {
    _loadApiKey();
  }

  final SharedPreferences _prefs;
  static const String _key = 'gemini_api_key';

  void _loadApiKey() {
    final saved = _prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  Future<void> setApiKey(String? apiKey) async {
    if (apiKey == null || apiKey.isEmpty) {
      state = null;
      await _prefs.remove(_key);
    } else {
      state = apiKey;
      await _prefs.setString(_key, apiKey);
    }
  }
}

// Провайдер для ExchangeRate API ключа
final exchangeRateApiKeyProvider =
    StateNotifierProvider<ExchangeRateApiKeyNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ExchangeRateApiKeyNotifier(prefs);
});

class ExchangeRateApiKeyNotifier extends StateNotifier<String?> {
  ExchangeRateApiKeyNotifier(this._prefs) : super(null) {
    _loadApiKey();
  }

  final SharedPreferences _prefs;
  static const String _key = 'exchange_rate_api_key';

  void _loadApiKey() {
    final saved = _prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  Future<void> setApiKey(String? apiKey) async {
    if (apiKey == null || apiKey.isEmpty) {
      state = null;
      await _prefs.remove(_key);
    } else {
      state = apiKey;
      await _prefs.setString(_key, apiKey);
    }
  }
}

// Провайдер для уменьшения анимаций (accessibility)
final reduceMotionProvider =
    StateNotifierProvider<ReduceMotionNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReduceMotionNotifier(prefs);
});

class ReduceMotionNotifier extends StateNotifier<bool> {
  ReduceMotionNotifier(this._prefs) : super(false) {
    _load();
  }

  final SharedPreferences _prefs;
  static const String _key = 'reduce_motion';

  void _load() {
    state = _prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_key, enabled);
  }
}

// Провайдер для модели Gemini
final geminiModelProvider =
    StateNotifierProvider<GeminiModelNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GeminiModelNotifier(prefs);
});

class GeminiModelNotifier extends StateNotifier<String> {
  GeminiModelNotifier(this._prefs) : super(GeminiModelIds.defaultId) {
    _loadModel();
  }

  final SharedPreferences _prefs;
  static const String _key = 'gemini_model';

  void _loadModel() {
    final saved = _prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    } else {
      state = GeminiModelIds.defaultId;
    }
  }

  Future<void> setModel(String model) async {
    if (model.isEmpty) {
      state = GeminiModelIds.defaultId;
      await _prefs.setString(_key, GeminiModelIds.defaultId);
    } else {
      state = model;
      await _prefs.setString(_key, model);
    }
  }
}
