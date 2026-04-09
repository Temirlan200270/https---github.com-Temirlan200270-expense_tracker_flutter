import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/currency_service.dart';

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final customApiKey = ref.watch(exchangeRateApiKeyProvider);
  return CurrencyService(prefs, customApiKey: customApiKey);
});

final exchangeRatesProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final service = ref.watch(currencyServiceProvider);
  return service.getExchangeRates();
});

final exchangeRateProvider = FutureProvider.autoDispose.family<double?, String>((ref, targetCurrency) async {
  final service = ref.watch(currencyServiceProvider);
  final baseCurrency = ref.watch(defaultCurrencyProvider);
  return service.getExchangeRate(baseCurrency, targetCurrency);
});

