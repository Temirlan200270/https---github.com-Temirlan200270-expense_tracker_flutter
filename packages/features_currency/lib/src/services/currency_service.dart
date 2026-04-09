import 'dart:convert';

import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  CurrencyService(this._prefs, {this.customApiKey});

  final SharedPreferences _prefs;
  final String? customApiKey;
  static const String _cacheKey = 'currency_rates_cache';
  static const String _cacheTimestampKey = 'currency_rates_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1);

  // Используем бесплатный API exchangerate-api.com
  // Если нужен API ключ, можно добавить его через настройки приложения
  String get _apiUrl {
    // Сначала проверяем кастомный ключ (из настроек приложения)
    String? apiKey = customApiKey;
    
    // Если нет ключа из настроек, пробуем из AppConfig (для разработки)
    apiKey ??= AppConfig.currencyApiKey;
    
    // Если есть API ключ, используем его
    if (apiKey != null && apiKey.isNotEmpty) {
      // Для exchangerate-api.com с ключом (v6):
      return 'https://v6.exchangerate-api.com/v6/$apiKey/latest/USD';
      // Или для fixer.io:
      // return 'https://api.fixer.io/latest?access_key=$apiKey';
    }
    
    // Бесплатный API без ключа (по умолчанию)
    return 'https://api.exchangerate-api.com/v4/latest/USD';
  }

  Future<Map<String, double>> getExchangeRates({bool forceRefresh = false}) async {
    // Проверяем кеш
    if (!forceRefresh) {
      final cached = await _getCachedRates();
      if (cached != null) {
        return cached;
      }
    }

    try {
      // Получаем курсы из API
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = (jsonData['rates'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, (value as num).toDouble()));

        // Сохраняем в кеш
        await _saveCachedRates(rates);

        return rates;
      } else {
        // Если API недоступен, возвращаем кеш или дефолтные значения
        final cached = await _getCachedRates();
        if (cached != null) {
          return cached;
        }
        return _getDefaultRates();
      }
    } catch (e) {
      // При ошибке возвращаем кеш или дефолтные значения
      final cached = await _getCachedRates();
      if (cached != null) {
        return cached;
      }
      return _getDefaultRates();
    }
  }

  Future<double?> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;

    final rates = await getExchangeRates();

    // API возвращает курсы относительно USD
    // Конвертируем: from -> USD -> to
    if (from == 'USD') {
      return rates[to];
    } else if (to == 'USD') {
      final fromRate = rates[from];
      return fromRate != null ? 1.0 / fromRate : null;
    } else {
      final fromRate = rates[from];
      final toRate = rates[to];
      if (fromRate != null && toRate != null) {
        return toRate / fromRate;
      }
    }

    return null;
  }

  Future<Map<String, double>?> _getCachedRates() async {
    final cachedJson = _prefs.getString(_cacheKey);
    final timestamp = _prefs.getInt(_cacheTimestampKey);

    if (cachedJson != null && timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // Проверяем, не устарел ли кеш
      if (now.difference(cacheTime) < _cacheDuration) {
        final ratesMap = jsonDecode(cachedJson) as Map<String, dynamic>;
        return ratesMap.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    }

    return null;
  }

  Future<void> _saveCachedRates(Map<String, double> rates) async {
    final json = jsonEncode(rates);
    await _prefs.setString(_cacheKey, json);
    await _prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, double> _getDefaultRates() {
    // Дефолтные курсы (примерные, на случай если API недоступен)
    return {
      'KZT': 450.0,
      'RUB': 90.0,
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 150.0,
      'CNY': 7.2,
    };
  }

  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
    await _prefs.remove(_cacheTimestampKey);
  }
}

