import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_models/shared_models.dart';

/// Результат сканирования чека
class ReceiptScanResult {
  ReceiptScanResult({
    required this.amount,
    this.date,
    this.merchant,
    this.rawText,
  });

  final Money amount;
  final DateTime? date;
  final String? merchant;
  final String? rawText;
}

/// Сервис для сканирования чеков через камеру
class ReceiptScannerService {
  late final TextRecognizer _textRecognizer;

  ReceiptScannerService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Распознать текст из изображения чека
  Future<String?> recognizeImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text.isNotEmpty ? recognizedText.text : null;
    } catch (e) {
      print('❌ Ошибка OCR распознавания: $e');
      return null;
    }
  }

  /// Сканировать чек и извлечь сумму и дату
  Future<ReceiptScanResult?> scanReceipt(File imageFile) async {
    try {
      final text = await recognizeImage(imageFile);
      if (text == null || text.isEmpty) {
        return null;
      }

      // Парсим сумму и дату из текста
      final amount = _extractAmount(text);
      final date = _extractDate(text);
      final merchant = _extractMerchant(text);

      if (amount == null) {
        return null;
      }

      return ReceiptScanResult(
        amount: amount,
        date: date,
        merchant: merchant,
        rawText: text,
      );
    } catch (e) {
      print('❌ Ошибка сканирования чека: $e');
      return null;
    }
  }

  /// Извлечь сумму из текста чека
  Money? _extractAmount(String text) {
    // Паттерны для поиска суммы:
    // - "Итого: 1500.00"
    // - "Total: 1500"
    // - "Сумма: 1 500"
    // - "ИТОГО 1500"
    // - "1500.00" в конце строки
    final patterns = [
      RegExp(r'(?:итого|total|сумма|сумма к оплате)[:\s]+([\d\s,\.]+)', caseSensitive: false),
      RegExp(r'([\d\s,\.]+)\s*(?:тенге|тг|₸|руб|рублей|₽|usd|\$|eur|€)', caseSensitive: false),
      RegExp(r'([\d\s,\.]+)\s*$', multiLine: true),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(RegExp(r'[\s,]'), '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          // Определяем валюту по контексту
          final currencyCode = _extractCurrency(text) ?? 'KZT';
          return Money(
            amountInCents: (amount * 100).round(),
            currencyCode: currencyCode,
          );
        }
      }
    }

    // Если не нашли по паттернам, ищем просто числа
    final numbers = RegExp(r'\b(\d+[.,]\d{2}|\d+)\b').allMatches(text);
    if (numbers.isNotEmpty) {
      // Берем последнее большое число (обычно это итоговая сумма)
      for (final match in numbers.toList().reversed) {
        final amountStr = match.group(0)?.replaceAll(',', '.') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount >= 100) {
          // Если сумма больше 100, вероятно это итоговая сумма
          final currencyCode = _extractCurrency(text) ?? 'KZT';
          return Money(
            amountInCents: (amount * 100).round(),
            currencyCode: currencyCode,
          );
        }
      }
    }

    return null;
  }

  /// Извлечь дату из текста чека
  DateTime? _extractDate(String text) {
    // Паттерны для даты:
    // - "01.12.2024"
    // - "2024-12-01"
    // - "01/12/2024"
    // - "01 декабря 2024"
    final patterns = [
      RegExp(r'(\d{2})[./](\d{2})[./](\d{4})'),
      RegExp(r'(\d{4})[./-](\d{2})[./-](\d{2})'),
      RegExp(r'(\d{1,2})\s+(?:января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря)\s+(\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (pattern == patterns[0] || pattern == patterns[1]) {
            // DD.MM.YYYY или YYYY-MM-DD
            final day = int.tryParse(match.group(1) ?? '');
            final month = int.tryParse(match.group(2) ?? '');
            final year = int.tryParse(match.group(3) ?? '');
            
            if (day != null && month != null && year != null) {
              // Если год в начале, это YYYY-MM-DD
              if (year > 2000 && day <= 12) {
                return DateTime(year, month, day);
              } else {
                // DD.MM.YYYY
                return DateTime(year, month, day);
              }
            }
          } else if (pattern == patterns[2]) {
            // Текстовый формат
            final day = int.tryParse(match.group(1) ?? '');
            final monthName = match.group(2)?.toLowerCase() ?? '';
            final year = int.tryParse(match.group(3) ?? '');
            
            if (day != null && year != null) {
              final monthMap = {
                'января': 1, 'февраля': 2, 'марта': 3, 'апреля': 4,
                'мая': 5, 'июня': 6, 'июля': 7, 'августа': 8,
                'сентября': 9, 'октября': 10, 'ноября': 11, 'декабря': 12,
              };
              final month = monthMap[monthName];
              if (month != null) {
                return DateTime(year, month, day);
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    // Если не нашли дату, возвращаем текущую дату
    return DateTime.now();
  }

  /// Извлечь название магазина/мерчанта
  String? _extractMerchant(String text) {
    // Обычно название магазина в начале текста
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return null;

    // Берем первую непустую строку, которая не похожа на дату/время/номер чека
    for (final line in lines.take(5)) {
      final trimmed = line.trim();
      if (trimmed.length > 3 && 
          !RegExp(r'^\d+[./-]\d+').hasMatch(trimmed) &&
          !RegExp(r'^\d+$').hasMatch(trimmed)) {
        return trimmed;
      }
    }

    return null;
  }

  /// Извлечь валюту из текста
  String? _extractCurrency(String text) {
    final currencyPatterns = {
      'KZT': [RegExp(r'тенге|тг|₸', caseSensitive: false)],
      'RUB': [RegExp(r'руб|рублей|₽', caseSensitive: false)],
      'USD': [RegExp(r'usd|\$', caseSensitive: false)],
      'EUR': [RegExp(r'eur|€', caseSensitive: false)],
    };

    for (final entry in currencyPatterns.entries) {
      for (final pattern in entry.value) {
        if (pattern.hasMatch(text)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

