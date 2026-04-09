class ExchangeRate {
  ExchangeRate({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rate,
    required this.updatedAt,
  });

  final String baseCurrency;
  final String targetCurrency;
  final double rate;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'baseCurrency': baseCurrency,
        'targetCurrency': targetCurrency,
        'rate': rate,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      baseCurrency: json['baseCurrency'] as String,
      targetCurrency: json['targetCurrency'] as String,
      rate: (json['rate'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ExchangeRatesResponse {
  ExchangeRatesResponse({
    required this.base,
    required this.rates,
    required this.timestamp,
  });

  final String base;
  final Map<String, double> rates;
  final int timestamp;

  factory ExchangeRatesResponse.fromJson(Map<String, dynamic> json) {
    final ratesMap = json['rates'] as Map<String, dynamic>;
    final rates = ratesMap.map((key, value) => MapEntry(key, (value as num).toDouble()));

    return ExchangeRatesResponse(
      base: json['base'] as String? ?? 'USD',
      rates: rates,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}

