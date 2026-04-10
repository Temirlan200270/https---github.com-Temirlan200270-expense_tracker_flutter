import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'kaspi_parser.dart';
import 'kaspi_ocr_service.dart';
import 'ai_ocr_service.dart';

class ImportService {
  /// Сборка [Expense] из результата Kaspi-парсера (на UI-потоке, после [compute]).
  List<Expense> _expensesFromParsed(
    List<ParsedTransaction> parsedTransactions, {
    required String currencyCode,
  }) {
    return parsedTransactions.map((tr) {
      return Expense(
        id: Uuid().v4(),
        amount: Money(
          amountInCents: (tr.amount * 100).round(),
          currencyCode: currencyCode,
        ),
        type: tr.isIncome ? ExpenseType.income : ExpenseType.expense,
        occurredAt: tr.date,
        categoryId: null,
        note: tr.title.isNotEmpty ? tr.title : tr.category,
      );
    }).toList();
  }

  Future<List<Expense>> importFromJson(File file) async {
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        throw FormatException('JSON файл пуст');
      }
      
      final jsonData = jsonDecode(content);
      
      // Поддержка двух форматов:
      // 1. Старый формат - массив транзакций напрямую
      // 2. Новый формат бэкапа - объект с полем 'expenses'
      List<dynamic> expensesList;
      
      if (jsonData is List) {
        // Старый формат: массив транзакций
        expensesList = jsonData;
      } else if (jsonData is Map<String, dynamic>) {
        // Поддержка разных форматов объектов:
        // 1. Формат бэкапа: объект с полем 'expenses'
        // 2. Формат выписки Kaspi: объект с полем 'transactions'
        final expenses = jsonData['expenses'];
        final transactions = jsonData['transactions'];
        
        if (expenses is List) {
          expensesList = expenses;
        } else if (transactions is List) {
          // Формат выписки Kaspi: конвертируем в формат Expense
          expensesList = transactions.map((tr) {
            if (tr is! Map<String, dynamic>) return null;
            
            final dateStr = tr['date']?.toString() ?? '';
            final amount = tr['amount'];
            final typeStr = tr['type']?.toString() ?? '';
            final details = tr['details']?.toString() ?? '';
            
            if (dateStr.isEmpty || amount == null) return null;
            
            // Парсинг даты (формат dd.MM.yy или dd.MM .yy с пробелом)
            DateTime? date;
            // Убираем пробелы вокруг точек (02.12 .25 -> 02.12.25)
            final normalizedDateStr = dateStr.replaceAll(' .', '.').replaceAll('. ', '.').trim();
            
            try {
              // Пробуем разные форматы
              if (normalizedDateStr.contains('.')) {
                final parts = normalizedDateStr.split('.');
                if (parts.length == 3) {
                  final day = int.parse(parts[0].trim());
                  final month = int.parse(parts[1].trim());
                  final yearStr = parts[2].trim();
                  final year = yearStr.length == 2 
                      ? 2000 + int.parse(yearStr)
                      : int.parse(yearStr);
                  date = DateTime(year, month, day);
                }
              }
              if (date == null) {
                // Пробуем стандартный парсинг
                date = DateTime.parse(normalizedDateStr);
              }
            } catch (_) {
              // Пробуем через DateFormat
              try {
                final dateFormats = [
                  DateFormat('dd.MM.yy'),
                  DateFormat('dd.MM.yyyy'),
                  DateFormat('yyyy-MM-dd'),
                ];
                for (final format in dateFormats) {
                  try {
                    date = format.parse(normalizedDateStr);
                    break;
                  } catch (_) {}
                }
              } catch (_) {
                return null;
              }
            }
            
            if (date == null) {
              return null;
            }
            
            // Определение типа транзакции
            final amountValue = amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0;
            final isIncome = amountValue > 0 || 
                typeStr.toLowerCase().contains('пополнение') ||
                typeStr.toLowerCase().contains('deposit');
            
            final now = DateTime.now();
            return {
              'id': Uuid().v4(),
              'amount': {
                'amountInCents': (amountValue.abs() * 100).round(),
                'currencyCode': jsonData['statement_info']?['currency']?.toString() ?? 'KZT',
              },
              'type': isIncome ? 'income' : 'expense',
              'occurredAt': date.toIso8601String(),
              'categoryId': null,
              'note': details.isNotEmpty ? details : null,
              'createdAt': now.toIso8601String(),
              'updatedAt': null,
              'deletedAt': null,
              'isDeleted': false,
            };
          }).whereType<Map<String, dynamic>>().toList();
        } else if (expenses == null && transactions == null) {
          throw FormatException('Неверный формат JSON: не найдено поле "expenses" или "transactions". Проверьте формат файла.');
        } else {
          throw FormatException('Неверный формат JSON: поля "expenses" и "transactions" должны быть массивами');
        }
      } else {
        throw FormatException('Неверный формат JSON: ожидается массив транзакций или объект с полем "expenses" или "transactions"');
      }
      
      if (expensesList.isEmpty) {
        return [];
      }
      
      final expenses = <Expense>[];
      int errorCount = 0;
      
      for (int i = 0; i < expensesList.length; i++) {
        try {
          final item = expensesList[i];
          if (item is! Map<String, dynamic>) {
            errorCount++;
            continue;
          }
          
          final expense = Expense.fromJson(item);
          expenses.add(expense);
        } catch (e) {
          errorCount++;
          continue;
        }
      }
      
      if (expenses.isEmpty && errorCount > 0) {
        throw FormatException('Не удалось распарсить ни одной транзакции из JSON. Проверьте формат файла.');
      }
      
      return expenses;
    } catch (e) {
      if (e is FormatException) {
        rethrow;
      }
      throw FormatException('Ошибка чтения JSON файла: $e');
    }
  }

  Future<List<Expense>> importFromCsv(File file) async {
    try {
      final content = await file.readAsString();
      // Используем CsvToListConverter с обработкой пустых полей
      final csvData = const CsvToListConverter(
        convertEmptyTo: null, // Пустые поля будут null
      ).convert(content);

      if (csvData.isEmpty) {
        throw FormatException('CSV файл пуст');
      }

      // Определяем формат по заголовку
      final header = csvData.first.map((e) => e?.toString().toLowerCase().trim() ?? '').toList();
      final dateIndex = header.indexOf('date') >= 0 ? header.indexOf('date') : 
                       (header.indexOf('дата') >= 0 ? header.indexOf('дата') : 0);
      final amountIndex = header.indexOf('amount') >= 0 ? header.indexOf('amount') : 
                         (header.indexOf('сумма') >= 0 ? header.indexOf('сумма') : 
                         (header.length > 1 ? 1 : -1));
      final currencyIndex = header.indexOf('currency') >= 0 ? header.indexOf('currency') : 
                           (header.indexOf('валюта') >= 0 ? header.indexOf('валюта') : 
                           (header.length > 2 ? 2 : -1));
      final operationIndex = header.indexOf('operation') >= 0 ? header.indexOf('operation') : 
                            (header.indexOf('тип') >= 0 ? header.indexOf('тип') : 
                            (header.indexOf('операция') >= 0 ? header.indexOf('операция') : -1));
      final detailsIndex = header.indexOf('details') >= 0 ? header.indexOf('details') : 
                          (header.indexOf('детали') >= 0 ? header.indexOf('детали') : 
                          (header.indexOf('заметка') >= 0 ? header.indexOf('заметка') : -1));
      
      // Определяем формат: старый (Дата, Тип, Сумма) или новый (Date, Amount, Currency, Operation, Details)
      final isNewFormat = dateIndex >= 0 && amountIndex >= 0 && 
                         (operationIndex >= 0 || detailsIndex >= 0);
      
      // Пропускаем заголовок
      final rows = csvData.skip(1).toList();
      final expenses = <Expense>[];
      int errorCount = 0;

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length < 2) {
          errorCount++;
          continue;
        }

        try {
          String dateStr;
          String amountStr;
          String? typeStr;
          String currencyCode = 'KZT';
          String? categoryId;
          String? note;
          
          if (isNewFormat) {
            // Новый формат: Date,Amount,Currency,Operation,Details
            dateStr = row.length > dateIndex ? row[dateIndex]?.toString().trim() ?? '' : '';
            amountStr = row.length > amountIndex ? row[amountIndex]?.toString().trim() ?? '' : '';
            currencyCode = currencyIndex >= 0 && row.length > currencyIndex 
                ? (row[currencyIndex]?.toString().trim() ?? 'KZT')
                : 'KZT';
            typeStr = operationIndex >= 0 && row.length > operationIndex
                ? row[operationIndex]?.toString().trim()
                : null;
            final detailsValue = detailsIndex >= 0 && row.length > detailsIndex
                ? row[detailsIndex]?.toString().trim()
                : null;
            note = detailsValue != null && detailsValue.isNotEmpty ? detailsValue : null;
          } else {
            // Старый формат: Дата, Тип, Сумма, Валюта, Категория, Заметка
            dateStr = row[0]?.toString().trim() ?? '';
            typeStr = row.length > 1 ? row[1]?.toString().trim() : null;
            amountStr = row.length > 2 ? (row[2]?.toString().trim() ?? '') : '';
            currencyCode = row.length > 3 && row[3] != null 
                ? row[3].toString().trim() 
                : 'KZT';
            categoryId = row.length > 4 && row[4] != null && row[4].toString().trim().isNotEmpty
                ? row[4].toString().trim()
                : null;
            note = row.length > 5 && row[5] != null && row[5].toString().trim().isNotEmpty
                ? row[5].toString().trim()
                : null;
          }
          
          if (dateStr.isEmpty || amountStr.isEmpty) {
            errorCount++;
            continue;
          }

          // Парсинг даты - поддерживаем разные форматы
          // Сначала пробуем DateFormat (для форматов типа dd.MM.yy), затем DateTime.parse
          DateTime? date;
          final dateFormats = [
            DateFormat('dd.MM.yy'),      // 02.12.25 (приоритет для Kaspi формата)
            DateFormat('dd.MM.yyyy'),    // 02.12.2025
            DateFormat('yyyy-MM-dd'),    // 2025-12-02
            DateFormat('dd/MM/yyyy'),    // 02/12/2025
            DateFormat('MM/dd/yyyy'),    // 12/02/2025
            DateFormat('dd-MM-yyyy'),    // 02-12-2025
          ];
          
          bool parsed = false;
          for (final format in dateFormats) {
            try {
              date = format.parse(dateStr);
              parsed = true;
              break;
            } catch (_) {}
          }
          
          // Если DateFormat не сработал, пробуем стандартный парсинг
          if (!parsed) {
            try {
              date = DateTime.parse(dateStr);
            } catch (_) {
              // Последняя попытка: парсим вручную для формата dd.MM.yy
              try {
                final parts = dateStr.split('.');
                if (parts.length == 3) {
                  final day = int.parse(parts[0].trim());
                  final month = int.parse(parts[1].trim());
                  final yearStr = parts[2].trim();
                  final year = yearStr.length == 2 
                      ? 2000 + int.parse(yearStr)
                      : int.parse(yearStr);
                  date = DateTime(year, month, day);
                }
              } catch (_) {}
            }
          }
          
          if (date == null) {
            errorCount++;
            continue;
          }

          // Парсинг суммы (может содержать знак + или -)
          // Убираем пробелы, заменяем запятую на точку, оставляем только цифры, точку и знак минус/плюс
          var cleanAmountStr = amountStr.replaceAll(' ', '').replaceAll('\u00A0', ''); // Убираем пробелы и неразрывные пробелы
          cleanAmountStr = cleanAmountStr.replaceAll(',', '.'); // Заменяем запятую на точку
          // Оставляем только цифры, точку и знак минус/плюс в начале
          cleanAmountStr = cleanAmountStr.replaceAll(RegExp(r'[^\d.-]'), '');
          // Убираем лишние знаки минус/плюс (оставляем только в начале)
          if (cleanAmountStr.startsWith('+')) {
            cleanAmountStr = cleanAmountStr.substring(1);
          }
          final amount = double.parse(cleanAmountStr);
          
          if (amount == 0) {
            errorCount++;
            continue;
          }

          // Определение типа транзакции
          // Если сумма отрицательная - это расход, если положительная - доход
          // Также проверяем поле Operation/Type
          ExpenseType type;
          if (amount < 0) {
            type = ExpenseType.expense;
          } else if (amount > 0) {
            type = ExpenseType.income;
          } else {
            // Если сумма 0, определяем по типу операции
            final typeStrLower = typeStr?.toLowerCase() ?? '';
            type = typeStrLower.contains('доход') ||
                    typeStrLower.contains('пополнение') ||
                    typeStrLower.contains('income') ||
                    typeStrLower.contains('deposit')
                ? ExpenseType.income
                : ExpenseType.expense;
          }
          
          // Используем абсолютное значение суммы
          final absAmount = amount.abs();

          expenses.add(
            Expense(
              id: Uuid().v4(),
              amount: Money(
                amountInCents: (absAmount * 100).round(),
                currencyCode: currencyCode.length == 3 ? currencyCode.toUpperCase() : 'KZT',
              ),
              type: type,
              occurredAt: date,
              categoryId: categoryId,
              note: note,
            ),
          );
        } catch (e) {
          // Пропускаем строки с ошибками парсинга
          errorCount++;
          continue;
        }
      }

      if (expenses.isEmpty && errorCount > 0) {
        throw FormatException('Не удалось распарсить ни одной строки из CSV. Проверьте формат файла.');
      }

      return expenses;
    } catch (e) {
      if (e is FormatException) {
        rethrow;
      }
      throw FormatException('Ошибка чтения CSV файла: $e');
    }
  }

  Future<List<Expense>> importFromPdf(File file,
      {String? geminiApiKey, String? geminiModel, WidgetRef? ref,
       String currencyCode = 'KZT'}) async {
    try {
      // Метод 1: AI OCR (Google Gemini) — самый надёжный способ
      try {
        final aiOcrService = AiOcrService(ref: ref);
        final recognizedText = await aiOcrService.recognizePdf(file,
            apiKey: geminiApiKey, model: geminiModel);

        if (recognizedText != null && recognizedText.isNotEmpty) {
          final parsedTransactions =
              await compute(kaspiParseForIsolate, recognizedText);

          if (parsedTransactions.isNotEmpty) {
            return _expensesFromParsed(parsedTransactions, currencyCode: currencyCode);
          }
        }
      } on GeminiApiException catch (e) {
        throw FormatException(
          'Ошибка Gemini (${e.statusCode}). Проверьте API-ключ и название модели в настройках.',
        );
      } catch (_) {
        // Gemini failed — fall through to ML Kit
      }

      // Метод 2: Пробуем OCR (Google ML Kit) — резервный способ
      try {
        final ocrService = KaspiOcrService();
        final recognizedText = await ocrService.recognizePdf(file);
        ocrService.dispose();

        if (recognizedText != null && recognizedText.isNotEmpty) {
          final parsedTransactions =
              await compute(kaspiParseForIsolate, recognizedText);

          if (parsedTransactions.isNotEmpty) {
            return _expensesFromParsed(parsedTransactions, currencyCode: currencyCode);
          }
        }
      } catch (_) {
        // ML Kit failed — fall through to binary extraction
      }

      // Метод 3: Бинарный поиск паттернов Kaspi в разных кодировках
      final bytes = await file.readAsBytes();

      final encodings = [utf8, latin1];

      for (final encoding in encodings) {
        try {
          final text = encoding.decode(bytes);

          final kaspiPattern = RegExp(
            r'(\d{2}\.\d{2}\.\d{2})\s*([-+])\s*([\d\s]+[,\.]\d{2})\s*[₸TтТ]\s*(Покупка|Пополнение|Перевод|Снятие|Разное)([^\n\r]*)',
            multiLine: true,
            caseSensitive: false,
          );

          final kaspiMatches = kaspiPattern.allMatches(text);

          if (kaspiMatches.isNotEmpty) {
            final textBuffer = StringBuffer();
            for (final match in kaspiMatches) {
              final fullMatch = match.group(0);
              if (fullMatch != null) {
                textBuffer.writeln(fullMatch);
              }
            }

            final extractedText = textBuffer.toString();
            if (extractedText.isNotEmpty) {
              final kaspiParser = KaspiStatementParser();
              final parsedTransactions = kaspiParser.parse(extractedText);

              if (parsedTransactions.isNotEmpty) {
                return _expensesFromParsed(parsedTransactions, currencyCode: currencyCode);
              }
            }
          }
        } catch (_) {
          continue;
        }
      }

      // Метод 4: Декомпрессия сжатых PDF-потоков
      final decompressedText = await _extractTextFromCompressedPdf(bytes);

      // Если декомпрессия не дала результатов, пробуем обычный метод
      final text = decompressedText.isNotEmpty
          ? decompressedText
          : String.fromCharCodes(bytes);

      // Извлекаем текст из PDF структуры
      // PDF хранит текст в разных форматах: (текст), <hex>, [текст]
      final extractedText = StringBuffer();
      final seenTexts = <String>{}; // Для избежания дубликатов

      // Если декомпрессия дала результат, добавляем его
      if (decompressedText.isNotEmpty) {
        extractedText.writeln(decompressedText);
      }

      // Метод 1: Текст в скобках (текст) - основной способ
      // Улучшенный паттерн: учитываем экранированные скобки
      final textPattern = RegExp(r'\(((?:[^()\\]|\\.|\([^)]*\))*)\)');
      final matches = textPattern.allMatches(text);
      for (final match in matches) {
        final textPart = match.group(1);
        if (textPart != null && textPart.trim().isNotEmpty) {
          var trimmed = textPart.trim();

          // Декодируем экранированные символы
          trimmed = trimmed.replaceAll(r'\\n', '\n');
          trimmed = trimmed.replaceAll(r'\\r', '\r');
          trimmed = trimmed.replaceAll(r'\\t', '\t');
          trimmed = trimmed.replaceAll(r'\\(', '(');
          trimmed = trimmed.replaceAll(r'\\)', ')');

          // Пропускаем служебные строки и короткие фрагменты
          if (trimmed.length > 1 &&
              !trimmed.contains('Font') &&
              !trimmed.contains('Type') &&
              !trimmed.contains('Subtype') &&
              !trimmed.startsWith('/') &&
              !RegExp(r'^[0-9\s\.]+$').hasMatch(trimmed) &&
              !seenTexts.contains(trimmed)) {
            seenTexts.add(trimmed);
            extractedText.writeln(trimmed);
          }
        }
      }

      // Метод 2: Текст в квадратных скобках [текст]
      final bracketPattern = RegExp(r'\[([^\]]+)\]');
      final bracketMatches = bracketPattern.allMatches(text);
      for (final match in bracketMatches) {
        final textPart = match.group(1);
        if (textPart != null && textPart.trim().isNotEmpty) {
          final trimmed = textPart.trim();
          // Проверяем, что это не служебная информация
          if (trimmed.length > 1 &&
              !trimmed.contains('Font') &&
              !trimmed.contains('Type') &&
              !RegExp(r'^[0-9\s\.]+$').hasMatch(trimmed) &&
              !seenTexts.contains(trimmed)) {
            seenTexts.add(trimmed);
            extractedText.writeln(trimmed);
          }
        }
      }

      // Метод 3: Декомпрессируем сжатые потоки (FlateDecode)
      // Ищем потоки с FlateDecode фильтром
      final streamPattern = RegExp(r'stream\s+(.*?)\s+endstream', dotAll: true);
      final filterPattern =
          RegExp(r'/Filter\s*/\s*FlateDecode', caseSensitive: false);
      final streamMatches = streamPattern.allMatches(text);

      for (final match in streamMatches) {
        // Проверяем, есть ли перед потоком FlateDecode
        final streamStart = match.start;
        final beforeStream = text.substring(
            (streamStart - 500).clamp(0, streamStart), streamStart);

        if (filterPattern.hasMatch(beforeStream)) {
          // Это сжатый поток, пытаемся декомпрессировать
          try {
            final streamBytes = match.group(1);
            if (streamBytes != null) {
              // Конвертируем строку в байты
              final bytes = streamBytes.codeUnits.map((c) => c & 0xFF).toList();

              // Пытаемся декомпрессировать через zlib
              try {
                final decompressed = Inflate(bytes).getBytes();
                final decompressedText = String.fromCharCodes(decompressed);

                // Ищем текстовые паттерны в декомпрессированном потоке
                final streamTextMatches =
                    textPattern.allMatches(decompressedText);
                for (final streamMatch in streamTextMatches) {
                  final streamText = streamMatch.group(1);
                  if (streamText != null && streamText.trim().length > 1) {
                    var trimmed = streamText.trim();
                    // Декодируем экранированные символы
                    trimmed = trimmed.replaceAll(r'\\n', '\n');
                    trimmed = trimmed.replaceAll(r'\\r', '\r');
                    trimmed = trimmed.replaceAll(r'\\t', '\t');
                    trimmed = trimmed.replaceAll(r'\\(', '(');
                    trimmed = trimmed.replaceAll(r'\\)', ')');

                    if (!seenTexts.contains(trimmed) &&
                        !trimmed.contains('Font') &&
                        !trimmed.contains('Type') &&
                        !trimmed.contains('Subtype') &&
                        trimmed.length > 2) {
                      seenTexts.add(trimmed);
                      extractedText.writeln(trimmed);
                    }
                  }
                }
              } catch (e) {
                // Если декомпрессия не удалась, пробуем извлечь читаемые символы
                final readableChars = <int>[];
                for (final byte in bytes) {
                  if ((byte >= 32 && byte <= 126) ||
                      byte == 9 ||
                      byte == 10 ||
                      byte == 13) {
                    readableChars.add(byte);
                  }
                }

                if (readableChars.length > 10) {
                  final decoded = String.fromCharCodes(readableChars);
                  if (decoded.trim().length > 5 &&
                      !seenTexts.contains(decoded)) {
                    seenTexts.add(decoded);
                    extractedText.writeln(decoded);
                  }
                }
              }
            }
          } catch (_) {
            // Игнорируем ошибки декомпрессии
          }
        } else {
          // Несжатый поток, извлекаем читаемые символы
          try {
            final streamContent = match.group(1);
            if (streamContent != null) {
              final readableChars = <int>[];
              for (final codeUnit in streamContent.codeUnits) {
                if ((codeUnit >= 32 && codeUnit <= 126) ||
                    codeUnit == 9 ||
                    codeUnit == 10 ||
                    codeUnit == 13) {
                  readableChars.add(codeUnit);
                }
              }

              if (readableChars.length > 10) {
                final decoded = String.fromCharCodes(readableChars);
                // Ищем текстовые паттерны
                final streamTextMatches = textPattern.allMatches(decoded);
                for (final streamMatch in streamTextMatches) {
                  final streamText = streamMatch.group(1);
                  if (streamText != null && streamText.trim().length > 1) {
                    var trimmed = streamText.trim();
                    trimmed = trimmed.replaceAll(r'\\n', '\n');
                    trimmed = trimmed.replaceAll(r'\\r', '\r');
                    trimmed = trimmed.replaceAll(r'\\t', '\t');

                    if (!seenTexts.contains(trimmed) &&
                        !trimmed.contains('Font') &&
                        !trimmed.contains('Type') &&
                        trimmed.length > 2) {
                      seenTexts.add(trimmed);
                      extractedText.writeln(trimmed);
                    }
                  }
                }
              }
            }
          } catch (_) {
            // Игнорируем ошибки
          }
        }
      }

      // Метод 4: Прямой поиск дат и сумм в тексте (для сложных PDF)
      // Ищем паттерны дат типа "02.12.25" или "02.12 .25"
      final datePattern = RegExp(r'\b(\d{1,2}\.\d{1,2}\s?\.?\s?\d{2,4})\b');
      final dateMatches = datePattern.allMatches(text);
      if (dateMatches.length > 5) {
        // Если нашли много дат, значит текст есть, но не извлекли правильно
        // Пробуем извлечь контекст вокруг дат
        for (final dateMatch in dateMatches) {
          final start = (dateMatch.start - 50).clamp(0, text.length);
          final end = (dateMatch.end + 200).clamp(0, text.length);
          final context = text.substring(start, end);

          // Ищем в контексте читаемый текст
          final contextText = String.fromCharCodes(context.codeUnits
              .where(
                  (c) => (c >= 32 && c <= 126) || c == 9 || c == 10 || c == 13)
              .toList());

          if (contextText.trim().length > 10 &&
              !seenTexts.contains(contextText)) {
            seenTexts.add(contextText);
            extractedText.writeln(contextText);
          }
        }
      }

      final allText = extractedText.toString();

      if (allText.trim().isEmpty) {
        throw Exception(
            'Не удалось извлечь текст из PDF. Файл может быть поврежден или иметь нестандартный формат. Попробуйте экспортировать данные в CSV или JSON формат.');
      }

      final lines = allText
          .split(RegExp(r'[\n\r]+'))
          .where((l) => l.trim().isNotEmpty)
          .toList();

      if (lines.isEmpty) {
        throw Exception(
            'Не удалось извлечь данные из PDF. Убедитесь, что файл содержит таблицу с данными.');
      }

      // Ищем заголовок таблицы
      int headerIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].toLowerCase();
        if ((line.contains('дата') || line.contains('date')) &&
            (line.contains('тип') ||
                line.contains('type') ||
                line.contains('сумма') ||
                line.contains('amount'))) {
          headerIndex = i;
          break;
        }
      }

      final dataLines = headerIndex >= 0
          ? lines.skip(headerIndex + 1).where((line) {
              final trimmed = line.trim().toLowerCase();
              return trimmed.isNotEmpty &&
                  !trimmed.contains('отчёт') &&
                  !trimmed.contains('report') &&
                  !trimmed.contains('сумма') &&
                  !trimmed.contains('amount') &&
                  !trimmed.contains('категория') &&
                  !trimmed.contains('category') &&
                  !trimmed.contains('заметка') &&
                  !trimmed.contains('note');
            }).toList()
          : lines;

      // Пробуем Kaspi парсер на полном тексте
      final fullText = allText.isNotEmpty ? allText : dataLines.join('\n');
      final kaspiParser = KaspiStatementParser();
      final parsedTransactions = kaspiParser.parse(fullText);

      if (parsedTransactions.isNotEmpty) {
        return _expensesFromParsed(parsedTransactions, currencyCode: currencyCode);
      }

      // Если Kaspi парсер не сработал, используем универсальный построчный парсинг
      return _parsePdfLines(dataLines, currencyCode: currencyCode);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw Exception(
          'Ошибка чтения PDF: $e. Убедитесь, что файл был экспортирован из этого приложения и содержит таблицу с данными.');
    }
  }

  Future<String> _extractTextFromCompressedPdf(List<int> bytes) async {
    final extractedText = StringBuffer();
    final seenTexts = <String>{};

    final text = utf8.decode(bytes, allowMalformed: true);
    final streamPattern = RegExp(r'stream\s+(.*?)\s+endstream', dotAll: true);
    final filterPattern =
        RegExp(r'/Filter\s*/\s*FlateDecode', caseSensitive: false);
    final streamMatches = streamPattern.allMatches(text);

    int processedStreams = 0;
    const maxStreams = 20;
    const maxStreamSize = 2 * 1024 * 1024;

    for (final match in streamMatches) {
      if (processedStreams >= maxStreams) break;

      final streamStart = match.start;
      final beforeStream = text.substring(
          (streamStart - 500).clamp(0, streamStart), streamStart);

      if (filterPattern.hasMatch(beforeStream)) {
        try {
          final streamStart = match.start;
          final streamEnd = match.end;
          
          final streamDataStart = text.indexOf('stream', streamStart);
          if (streamDataStart == -1) continue;
          
          final streamDataEnd = text.lastIndexOf('endstream', streamEnd);
          if (streamDataEnd == -1) continue;
          
          final streamTextStart = streamDataStart + 6;
          final streamTextEnd = streamDataEnd;
          
          final streamBytesStart = (streamTextStart * bytes.length / text.length).round();
          final streamBytesEnd = (streamTextEnd * bytes.length / text.length).round();
          
          if (streamBytesEnd <= streamBytesStart || 
              streamBytesEnd - streamBytesStart > maxStreamSize) {
            continue;
          }
          
          final streamBytes = bytes.sublist(
            streamBytesStart.clamp(0, bytes.length),
            streamBytesEnd.clamp(0, bytes.length),
          );
          
          if (streamBytes.isEmpty || streamBytes.length > maxStreamSize) continue;

          try {
            final decompressed = Inflate(streamBytes).getBytes();
            if (decompressed.length > 10 * 1024 * 1024) continue;

            final decompressedText = String.fromCharCodes(decompressed);

            final readableChars = <int>[];
            for (final byte in decompressed) {
              if ((byte >= 32 && byte <= 126) ||
                  byte == 9 || byte == 10 || byte == 13) {
                readableChars.add(byte);
              }
            }

            if (readableChars.length > 10) {
              final readableText = String.fromCharCodes(readableChars);
              if (readableText.length > 20 &&
                  !seenTexts.contains(readableText)) {
                seenTexts.add(readableText);
                extractedText.writeln(readableText);
              }
            }

            // Hex text objects
            final hexTextPattern = RegExp(r'<([0-9A-Fa-f]+)>');
            final hexMatches = hexTextPattern.allMatches(decompressedText);
            if (hexMatches.isNotEmpty) {
              int hexCount = 0;
              for (final hexMatch in hexMatches) {
                if (hexCount++ >= 3) break;
                final hexStr = hexMatch.group(1);
                if (hexStr != null && hexStr.isNotEmpty) {
                  try {
                    final hexBytes = <int>[];
                    for (int i = 0; i < hexStr.length; i += 2) {
                      if (i + 1 < hexStr.length) {
                        hexBytes.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
                      }
                    }
                    if (hexBytes.isNotEmpty) {
                      final decodedText = String.fromCharCodes(hexBytes);
                      if (_isValidText(decodedText) &&
                          !seenTexts.contains(decodedText)) {
                        seenTexts.add(decodedText);
                        extractedText.writeln(decodedText);
                      }
                    }
                  } catch (_) {}
                }
              }
            }

            // PDF text operators: (text) Tj
            final tjPattern = RegExp(r'\(([^)]+)\)\s+Tj');
            for (final m in tjPattern.allMatches(decompressedText)) {
              final textPart = m.group(1);
              if (textPart != null && textPart.trim().isNotEmpty) {
                final trimmed = _decodePdfText(textPart);
                if (_isValidText(trimmed) && !seenTexts.contains(trimmed)) {
                  seenTexts.add(trimmed);
                  extractedText.writeln(trimmed);
                }
              }
            }

            // [(text1) (text2) ...] TJ
            final tjArrayPattern = RegExp(r'\[(.*?)\]\s*TJ', dotAll: true);
            for (final m in tjArrayPattern.allMatches(decompressedText)) {
              final arrayContent = m.group(1);
              if (arrayContent != null) {
                for (final textMatch in RegExp(r'\(([^)]+)\)').allMatches(arrayContent)) {
                  final textPart = textMatch.group(1);
                  if (textPart != null && textPart.trim().isNotEmpty) {
                    final trimmed = _decodePdfText(textPart);
                    if (_isValidText(trimmed) && !seenTexts.contains(trimmed)) {
                      seenTexts.add(trimmed);
                      extractedText.writeln(trimmed);
                    }
                  }
                }
              }
            }

            // (text) ' or (text) "
            final quotePattern = RegExp(r'\(([^)]+)\)\s*[' '"]');
            for (final m in quotePattern.allMatches(decompressedText)) {
              final textPart = m.group(1);
              if (textPart != null && textPart.trim().isNotEmpty) {
                final trimmed = _decodePdfText(textPart);
                if (_isValidText(trimmed) && !seenTexts.contains(trimmed)) {
                  seenTexts.add(trimmed);
                  extractedText.writeln(trimmed);
                }
              }
            }

            // Simple text in parentheses
            final simpleTextPattern = RegExp(r'\(([^)]+)\)');
            for (final m in simpleTextPattern.allMatches(decompressedText)) {
              final textPart = m.group(1);
              if (textPart != null && textPart.trim().length > 1) {
                final trimmed = _decodePdfText(textPart);
                if (_isValidText(trimmed) && !seenTexts.contains(trimmed)) {
                  seenTexts.add(trimmed);
                  extractedText.writeln(trimmed);
                }
              }
            }

            processedStreams++;
          } catch (_) {}
        } catch (_) {}
      }
    }

    return extractedText.toString();
  }

  String _decodePdfText(String text) {
    // Декодируем экранированные символы PDF
    var decoded = text;
    decoded = decoded.replaceAll(r'\\n', '\n');
    decoded = decoded.replaceAll(r'\\r', '\r');
    decoded = decoded.replaceAll(r'\\t', '\t');
    decoded = decoded.replaceAll(r'\\(', '(');
    decoded = decoded.replaceAll(r'\\)', ')');
    decoded = decoded.replaceAll(r'\\', '');
    return decoded.trim();
  }

  bool _isValidText(String text) {
    if (text.isEmpty || text.length < 2) return false;

    // Пропускаем служебные строки
    if (text.contains('Font') ||
        text.contains('Type') ||
        text.contains('Subtype') ||
        text.startsWith('/') ||
        text.startsWith('BT') ||
        text.startsWith('ET')) {
      return false;
    }

    // Пропускаем только числа (координаты)
    if (RegExp(r'^[\d\s\.\-\+]+$').hasMatch(text)) {
      return false;
    }

    // Пропускаем очень короткие строки из одних символов
    if (text.length < 3 && RegExp(r'^[^\w]+$').hasMatch(text)) {
      return false;
    }

    return true;
  }

  List<Expense> _parsePdfLines(List<String> lines, {String currencyCode = 'KZT'}) {
    final expenses = <Expense>[];
    final dateFormats = [
      DateFormat('dd.MM.yy'), // 02.12.25
      DateFormat('dd.MM .yy'), // 02.12 .25 (с пробелом)
      DateFormat('dd.MM.yyyy'), // 02.12.2025
      DateFormat('dd.MM .yyyy'), // 02.12 .2025 (с пробелом)
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('yyyy.MM.dd'),
    ];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        // Улучшенный парсинг: обрабатываем разные разделители
        // Пробуем разные варианты разделения: табуляция, множественные пробелы, разделители таблиц
        List<String> parts;

        // Сначала пробуем разделители таблиц | (приоритет для Kaspi формата)
        if (line.contains('|')) {
          parts = line
              .split('|')
              .map((p) => p.trim())
              .where((p) =>
                  p.isNotEmpty &&
                  !p.contains(':--') &&
                  !p.contains('--:') &&
                  p != ':' &&
                  p.length > 1)
              .toList();
        }
        // Затем табуляцию
        else if (line.contains('\t')) {
          parts = line.split('\t').where((p) => p.trim().isNotEmpty).toList();
        }
        // Затем множественные пробелы (2+)
        else if (RegExp(r'\s{2,}').hasMatch(line)) {
          parts = line
              .split(RegExp(r'\s{2,}'))
              .where((p) => p.trim().isNotEmpty)
              .toList();
        }
        // Или пробуем разделитель ;
        else if (line.contains(';')) {
          parts = line.split(';').where((p) => p.trim().isNotEmpty).toList();
        }
        // Иначе разбиваем по обычным пробелам, но фильтруем короткие части
        else {
          parts = line
              .split(RegExp(r'\s+'))
              .where((p) => p.trim().isNotEmpty && p.trim().length > 1)
              .toList();
        }

        if (parts.length < 2) continue;

        // Пытаемся найти дату
        DateTime? date;
        int dateIndex = -1;
        for (int i = 0; i < parts.length; i++) {
          // Очищаем от лишних символов
          var dateStr = parts[i].trim();
          // Убираем LaTeX команды и лишние пробелы
          dateStr = dateStr.replaceAll(RegExp(r'\\text\s*\{[^}]*\}'), '');
          dateStr = dateStr.replaceAll(RegExp(r'\\boldsymbol\s*\{[^}]*\}'), '');
          dateStr = dateStr.replaceAll(RegExp(r'\$'), '');
          dateStr = dateStr.trim();

          // Пропускаем части, которые явно не даты
          if (dateStr.length < 5 || dateStr.length > 15) continue;
          if (RegExp(r'^[+-]?[\d\s,\.]+').hasMatch(dateStr) &&
              !dateStr.contains('.')) continue;

          for (final format in dateFormats) {
            try {
              date = format.parse(dateStr);
              dateIndex = i;
              break;
            } catch (_) {
              // Пробуем парсить с учетом возможных пробелов в дате (02.12 .25)
              try {
                final normalizedDate =
                    dateStr.replaceAll(' .', '.').replaceAll('. ', '.');
                date = format.parse(normalizedDate);
                dateIndex = i;
                break;
              } catch (_) {}
            }
          }
          if (date != null) break;
        }

        if (date == null) continue;

        double? amount;
        int amountIndex = -1;

        // Улучшенный regex для сумм
        final amountPatterns = [
          // Формат с $ и LaTeX: "$-1000,00 \text { T }$" или "$+2000,00 \boldsymbol{T}$"
          RegExp(
              r'\$?([+-]?)\s*([\d\s,\.]+)\s*(?:\\text\s*\{[^}]*\}|\boldsymbol\{[^}]*\}|T|₸|тенге)',
              caseSensitive: false),
          // Формат без $: "- 900,00 T" или "+ 2000,00 T"
          RegExp(r'([+-]?)\s*([\d\s,\.]+)\s*(?:T|₸|тенге)',
              caseSensitive: false),
          // Простой формат: "1000,00" или "-1000.00"
          RegExp(r'([+-]?)\s*([\d\s,\.]+)'),
        ];

        for (int i = 0; i < parts.length; i++) {
          if (i == dateIndex) continue;

          final part = parts[i].trim();
          bool found = false;

          for (final pattern in amountPatterns) {
            final match = pattern.firstMatch(part);
            if (match != null) {
              try {
                final sign = match.group(1) ?? '';
                var amountStr =
                    match.group(2)?.replaceAll(RegExp(r'[\s]'), '') ?? '';
                // Заменяем запятую на точку для парсинга
                amountStr = amountStr.replaceAll(',', '.');

                var parsedAmount = double.parse(amountStr);

                // Учитываем знак
                if (sign == '-' || part.contains('-')) {
                  parsedAmount = -parsedAmount.abs();
                } else if (sign == '+' || part.contains('+')) {
                  parsedAmount = parsedAmount.abs();
                }

                // Если сумма отрицательная, это расход, иначе доход
                if (parsedAmount != 0) {
                  amount = parsedAmount.abs();
                  amountIndex = i;
                  found = true;
                  break;
                }
              } catch (_) {}
            }
          }
          if (found) break;
        }

        if (amount == null || amount <= 0) continue;

        // Определяем тип (доход/расход) по знаку суммы и тексту операции
        ExpenseType type = ExpenseType.expense;

        // Ищем текст операции в частях
        String? operationText;
        for (int i = 0; i < parts.length; i++) {
          if (i != dateIndex && i != amountIndex) {
            final part = parts[i].toLowerCase();
            if (part.contains('пополнение') ||
                part.contains('доход') ||
                part.contains('income') ||
                part.contains('deposit')) {
              type = ExpenseType.income;
              operationText = parts[i];
              break;
            } else if (part.contains('покупка') ||
                part.contains('перевод') ||
                part.contains('снятие') ||
                part.contains('расход') ||
                part.contains('expense') ||
                part.contains('purchase') ||
                part.contains('transfer') ||
                part.contains('withdrawal')) {
              type = ExpenseType.expense;
              operationText = parts[i];
              break;
            }
          }
        }

        // Если не нашли по тексту, определяем по знаку суммы
        if (operationText == null) {
          // Проверяем исходную строку на знак
          final originalAmountPart = parts[amountIndex];
          if (originalAmountPart.contains('-') ||
              originalAmountPart.startsWith('-')) {
            type = ExpenseType.expense;
          } else if (originalAmountPart.contains('+') ||
              originalAmountPart.startsWith('+')) {
            type = ExpenseType.income;
          }
        }

        // Категория и заметка (остальные части)
        String? categoryId;
        String? note;
        final otherParts = <String>[];
        for (int i = 0; i < parts.length; i++) {
          if (i != dateIndex && i != amountIndex) {
            var part = parts[i].trim();
            // Очищаем от LaTeX команд
            part = part.replaceAll(RegExp(r'\\text\s*\{[^}]*\}'), '');
            part = part.replaceAll(RegExp(r'\\boldsymbol\s*\{[^}]*\}'), '');
            part = part.replaceAll(RegExp(r'\$'), '');
            part = part.trim();
            if (part.isNotEmpty) {
              otherParts.add(part);
            }
          }
        }

        if (otherParts.isNotEmpty) {
          // Для Kaspi формата: [Дата] [Сумма] [Операция] [Детали]
          // Операция обычно короткая (Покупка, Пополнение, Перевод, Снятие)
          // Детали - это название места/человека

          if (otherParts.length >= 2) {
            // Первая часть - операция (Покупка, Пополнение, Перевод, Снятие)
            // Остальное - детали (заметка)
            note = otherParts.skip(1).join(' ').trim();
            note = note.isEmpty ? null : note;

            // Можно использовать операцию как категорию, но лучше оставить null
            // и позволить пользователю выбрать категорию вручную
            categoryId = null;
          } else if (otherParts.length == 1) {
            // Только одна часть - это заметка
            note = otherParts[0].isEmpty ? null : otherParts[0];
          }
        }

        expenses.add(
          Expense(
            id: Uuid().v4(),
            amount: Money(
              amountInCents: (amount * 100).round(),
              currencyCode: currencyCode,
            ),
            type: type,
            occurredAt: date,
            categoryId: categoryId?.isEmpty ?? true ? null : categoryId,
            note: note?.isEmpty ?? true ? null : note,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    return expenses;
  }

  List<String> validateImportData(List<Expense> expenses) {
    final errors = <String>[];

    for (var i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      if (expense.amount.amountInCents <= 0) {
        errors.add('Строка ${i + 1}: Сумма должна быть больше 0');
      }
      if (expense.amount.currencyCode.length != 3) {
        errors.add('Строка ${i + 1}: Неверный код валюты');
      }
    }

    return errors;
  }
}
