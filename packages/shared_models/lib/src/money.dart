import 'package:intl/intl.dart';

/// Простое значение для хранения суммы в минимальных единицах и кода валюты.
class Money {
  const Money({
    required this.amountInCents,
    required this.currencyCode,
  }) : assert(currencyCode.length == 3, 'Код валюты должен состоять из 3 символов');

  final int amountInCents;
  final String currencyCode;

  double get amount => amountInCents / 100;

  Money copyWith({
    int? amountInCents,
    String? currencyCode,
  }) {
    return Money(
      amountInCents: amountInCents ?? this.amountInCents,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  String format({NumberFormat? formatter, String? locale}) {
    final format = formatter ??
        NumberFormat.currency(
          locale: locale,
          symbol: currencyCode,
          decimalDigits: 2,
        );
    return format.format(amount);
  }

  Map<String, dynamic> toJson() => {
        'amountInCents': amountInCents,
        'currencyCode': currencyCode,
      };

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amountInCents: json['amountInCents'] as int,
      currencyCode: json['currencyCode'] as String,
    );
  }
}

