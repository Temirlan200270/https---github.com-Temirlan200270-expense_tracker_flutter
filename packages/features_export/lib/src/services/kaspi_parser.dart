import 'package:intl/intl.dart';

class ParsedTransaction {
  final DateTime date;
  final double amount;
  final String title;      // Например: "Game Republic Каирбаева"
  final String category;   // Например: "Покупка"
  final bool isIncome;

  ParsedTransaction({
    required this.date,
    required this.amount,
    required this.title,
    required this.category,
    required this.isIncome,
  });

  @override
  String toString() => '$date | $amount | $category | $title';
}

class KaspiStatementParser {
  /// Парсит сырой текст из PDF
  List<ParsedTransaction> parse(String rawText) {
    final List<ParsedTransaction> transactions = [];
    final List<String> unrecognizedLines = []; // Для отладки
    final Set<String> processedTransactions = {}; // Для избежания дубликатов
    
    // Разбиваем текст на строки и чистим от лишних пробелов по краям
    final lines = rawText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    print('📊 Всего строк в тексте: ${lines.length}');

    // Регулярное выражение под формат Kaspi Gold
    // Поддерживаем форматы: "02.12.25", "02.12 .25" (с пробелом), "$-1000,00 \text { T }$", таблицы markdown
    // Улучшенный regex для распознавания всех форматов, включая без пробелов между датой и суммой
    // Более гибкий regex - позволяет пробелы в любых местах
    final regex = RegExp(
      r'(\d{2}\.\d{2}\s*\.?\s*\d{2})\s+([-+])\s*([\d\s]+[,\.]\d{2})\s*(?:₸|T|тенге|\$|\\text\s*\{[^}]*\}|\boldsymbol\{[^}]*\})?\s*(Покупка|Пополнение|Перевод|Снятие|Разное)(.*)',
      caseSensitive: false,
    );
    
    // Дополнительный regex для формата без пробела между датой и суммой: "02.12.25-1000,00"
    final regexNoSpace = RegExp(
      r'(\d{2}\.\d{2}\s*\.?\s*\d{2})\s*([-+])\s*([\d\s]+[,\.]\d{2})\s*(?:₸|T|тенге|\$|\\text\s*\{[^}]*\}|\boldsymbol\{[^}]*\})?\s*(Покупка|Пополнение|Перевод|Снятие|Разное)(.*)',
      caseSensitive: false,
    );
    
    // Еще более гибкий regex - ищем паттерн в любом месте строки
    final regexFlexible = RegExp(
      r'(\d{2}\.\d{2}\s*\.?\s*\d{2})\s*([-+])\s*([\d\s,\.]+)\s*(?:₸|T|тенге|\$|\\text\s*\{[^}]*\}|\boldsymbol\{[^}]*\})?\s*(Покупка|Пополнение|Перевод|Снятие|Разное)',
      caseSensitive: false,
    );
    
    // Альтернативный regex для формата с $ и LaTeX (более гибкий)
    final regexLaTeX = RegExp(
      r'\$([-+])\s*([\d\s,\.]+)\s*(?:\\text\s*\{[^}]*\}|\boldsymbol\{[^}]*\}|T|₸|тенге)\$\s*(Покупка|Пополнение|Перевод|Снятие|Разное)',
      caseSensitive: false,
    );
    
    // Regex для таблиц markdown (формат: | 02.12.25 | $-1000,00 T$ | Покупка | Детали |)
    final regexMarkdownTable = RegExp(
      r'^\|\s*(\d{2}\.\d{2}\s*\.?\s*\d{2})\s*\|\s*\$?([-+])\s*([\d\s,\.]+)\s*(?:\\text\s*\{[^}]*\}|\boldsymbol\{[^}]*\}|T|₸|тенге|\$)?\s*\$\s*\|\s*(Покупка|Пополнение|Перевод|Снятие|Разное)\s*\|\s*(.+?)\s*\|',
      caseSensitive: false,
    );
    
    // Regex для упрощенного формата таблицы (без $)
    final regexSimpleTable = RegExp(
      r'^\|\s*(\d{2}\.\d{2}\s*\.?\s*\d{2})\s*\|\s*([-+])\s*([\d\s,\.]+)\s*(?:T|₸|тенге)?\s*\|\s*(Покупка|Пополнение|Перевод|Снятие|Разное)\s*\|\s*(.+?)\s*\|',
      caseSensitive: false,
    );
    
    // Regex для поиска транзакций в полном тексте (без привязки к началу строки)
    final regexFullText = RegExp(
      r'(\d{2}\.\d{2}\s*\.?\s*\d{2})\s+([-+])\s+([\d\s,\.]+)\s*(?:₸|T|тенге)?\s+(Покупка|Пополнение|Перевод|Снятие|Разное)\s+([^\n\|]+)',
      caseSensitive: false,
    );
    
    // Regex для таблиц в полном тексте
    final regexTableFullText = RegExp(
      r'\|\s*(\d{2}\.\d{2}\s*\.?\s*\d{2})\s*\|\s*([-+])\s*([\d\s,\.]+)\s*(?:₸|T|тенге)?\s*\|\s*(Покупка|Пополнение|Перевод|Снятие|Разное)\s*\|\s*([^\|]+)\s*\|',
      caseSensitive: false,
    );

    // Сначала ищем все транзакции в полном тексте (это помогает найти разбитые транзакции)
    final fullTextMatches = <Map<String, String?>>{};
    
    for (final regex in [regexTableFullText, regexFullText, regexMarkdownTable, regexSimpleTable]) {
      final matches = regex.allMatches(rawText);
      for (final match in matches) {
        final dateStr = match.group(1);
        final sign = match.group(2);
        final amountStr = match.group(3);
        final type = match.group(4);
        final details = match.group(5);
        
        if (dateStr != null && sign != null && amountStr != null && type != null) {
          final key = '$dateStr|$sign|$amountStr|$type';
          if (!fullTextMatches.any((m) => m['key'] == key)) {
            fullTextMatches.add({
              'key': key,
              'date': dateStr,
              'sign': sign,
              'amount': amountStr,
              'type': type,
              'details': details ?? '',
            });
          }
        }
      }
    }
    
    print('📊 Найдено транзакций в полном тексте: ${fullTextMatches.length}');

    // Также пробуем парсить многострочные блоки (для таблиц markdown)
    // Объединяем строки, которые могут быть частью одной транзакции
    final processedLines = <String>[];
    String? currentLine;
    
    for (var line in lines) {
      final trimmed = line.trim();
      
      // Пропускаем пустые строки и разделители таблиц
      if (trimmed.isEmpty || trimmed == '---' || trimmed == '|---|---|---|' || 
          trimmed.startsWith('|---|---')) {
        if (currentLine != null) {
          processedLines.add(currentLine);
          currentLine = null;
        }
        continue;
      }
      
      // Если строка начинается с даты или с | и содержит дату, это новая транзакция
      final hasDate = RegExp(r'\d{2}\.\d{2}\s*\.?\s*\d{2}').hasMatch(trimmed);
      final startsWithDate = RegExp(r'^\d{2}\.\d{2}').hasMatch(trimmed);
      final startsWithTable = RegExp(r'^\|\s*\d{2}\.\d{2}').hasMatch(trimmed);
      
      if (hasDate && (startsWithDate || startsWithTable)) {
        if (currentLine != null) {
          processedLines.add(currentLine);
        }
        currentLine = trimmed;
      } else if (currentLine != null) {
        // Продолжение предыдущей строки (если не начинается с новой даты)
        if (!hasDate || trimmed.length < 20) {
          currentLine += ' ' + trimmed;
        } else {
          // Это новая транзакция, сохраняем предыдущую
          processedLines.add(currentLine);
          currentLine = trimmed;
        }
      } else {
        // Новая строка без даты в начале, но может содержать транзакцию
        processedLines.add(trimmed);
      }
    }
    
    // Добавляем последнюю строку
    if (currentLine != null) {
      processedLines.add(currentLine);
    }
    
    print('📊 Обработано строк: ${lines.length} -> ${processedLines.length} (после объединения)');
    
    // Обрабатываем транзакции, найденные в полном тексте
    for (final matchData in fullTextMatches) {
      final dateStr = matchData['date'];
      final sign = matchData['sign'];
      final amountStr = matchData['amount'];
      final type = matchData['type'];
      final details = matchData['details'] ?? '';
      
      if (dateStr != null && sign != null && amountStr != null && type != null) {
        try {
          final transaction = _parseTransaction(
            dateStr: dateStr,
            sign: sign,
            amountStr: amountStr,
            type: type,
            details: details,
            line: 'FULL_TEXT_MATCH',
          );
          if (transaction != null) {
            final key = '$dateStr|$sign|$amountStr|$type|$details';
            if (!processedTransactions.contains(key)) {
              processedTransactions.add(key);
              transactions.add(transaction);
            }
          }
        } catch (e) {
          // Игнорируем ошибки парсинга
        }
      }
    }
    
    // Теперь обрабатываем строки построчно
    for (var line in processedLines) {
      // Пропускаем заголовки таблиц и разделители
      if (line.toLowerCase().contains('дата') && 
          (line.toLowerCase().contains('сумма') || line.toLowerCase().contains('операция'))) {
        continue;
      }
      
      // Пропускаем разделители таблиц
      if (line == '---' || line.startsWith('|---|---')) {
        continue;
      }

      // Пробуем разные форматы по приоритету
      String? dateStr;
      String? sign;
      String? amountStr;
      String? type;
      String? details;
      
      // 1. Пробуем формат markdown таблицы
      var match = regexMarkdownTable.firstMatch(line);
      if (match != null) {
        dateStr = match.group(1);
        sign = match.group(2);
        amountStr = match.group(3);
        type = match.group(4);
        details = match.group(5);
      } else {
        // 2. Пробуем упрощенный формат таблицы
        match = regexSimpleTable.firstMatch(line);
        if (match != null) {
          dateStr = match.group(1);
          sign = match.group(2);
          amountStr = match.group(3);
          type = match.group(4);
          details = match.group(5);
        } else {
          // 3. Пробуем обычный формат
          match = regex.firstMatch(line);
          if (match != null) {
            dateStr = match.group(1);
            sign = match.group(2);
            amountStr = match.group(3);
            type = match.group(4);
            details = match.group(5);
          } else {
            // 3.5. Пробуем формат без пробела между датой и суммой
            match = regexNoSpace.firstMatch(line);
            if (match != null) {
              dateStr = match.group(1);
              sign = match.group(2);
              amountStr = match.group(3);
              type = match.group(4);
              details = match.group(5);
            } else {
              // 3.6. Пробуем гибкий формат (ищем паттерн в любом месте строки)
              match = regexFlexible.firstMatch(line);
              if (match != null) {
                dateStr = match.group(1);
                sign = match.group(2);
                amountStr = match.group(3);
                type = match.group(4);
                // Ищем детали после типа операции
                final detailsMatch = RegExp(
                  r'(?:Покупка|Пополнение|Перевод|Снятие|Разное)\s+(.+?)(?:\s*$|\s*\||\s*₸|\s*T)',
                  caseSensitive: false,
                ).firstMatch(line);
                details = detailsMatch?.group(1);
              } else {
                // 4. Пробуем формат с LaTeX
                final latexMatch = regexLaTeX.firstMatch(line);
                if (latexMatch != null) {
                  sign = latexMatch.group(1);
                  amountStr = latexMatch.group(2);
                  type = latexMatch.group(3);
                  // Ищем дату отдельно в строке
                  final dateMatch = RegExp(r'(\d{2}\.\d{2}\s*\.?\s*\d{2})').firstMatch(line);
                  if (dateMatch != null) {
                    dateStr = dateMatch.group(1);
                  }
                  // Детали - остаток строки после типа
                  final detailsMatch = RegExp(r'(?:Покупка|Пополнение|Перевод|Снятие|Разное)\s+(.+)$', caseSensitive: false).firstMatch(line);
                  details = detailsMatch?.group(1);
                }
              }
            }
          }
        }
      }
      
      if (dateStr != null && sign != null && amountStr != null && type != null) {
        final transaction = _parseTransaction(
          dateStr: dateStr,
          sign: sign,
          amountStr: amountStr,
          type: type,
          details: details ?? '',
          line: line,
        );
        
        if (transaction != null) {
          final key = '$dateStr|$sign|$amountStr|$type|${transaction.title}';
          if (!processedTransactions.contains(key)) {
            processedTransactions.add(key);
            transactions.add(transaction);
          }
        }
      } else {
        // Сохраняем нераспознанные строки для отладки (только если похожи на транзакции)
        if (line.length > 10 && 
            RegExp(r'\d{2}\.\d{2}').hasMatch(line) &&
            (line.contains('Покупка') || line.contains('Пополнение') || 
             line.contains('Перевод') || line.contains('Снятие'))) {
          unrecognizedLines.add(line);
        }
      }
    }
    
    // Логируем нераспознанные строки для отладки
    if (unrecognizedLines.isNotEmpty) {
      print('⚠️ Нераспознано ${unrecognizedLines.length} строк, похожих на транзакции:');
      for (int i = 0; i < unrecognizedLines.length && i < 10; i++) {
        print('  ${i + 1}. ${unrecognizedLines[i]}');
      }
      if (unrecognizedLines.length > 10) {
        print('  ... и еще ${unrecognizedLines.length - 10} строк');
      }
    }
    
    // Подсчитываем статистику
    final incomeCount = transactions.where((t) => t.isIncome).length;
    final expenseCount = transactions.where((t) => !t.isIncome).length;
    final totalIncome = transactions.where((t) => t.isIncome).fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions.where((t) => !t.isIncome).fold<double>(0, (sum, t) => sum + t.amount);
    
    print('✅ Всего распознано транзакций: ${transactions.length}');
    print('📊 Статистика парсера:');
    print('   Доходы: $incomeCount записей, ${totalIncome.toStringAsFixed(2)} KZT');
    print('   Расходы: $expenseCount записей, ${totalExpenses.toStringAsFixed(2)} KZT');
    print('   Баланс: ${(totalIncome - totalExpenses).toStringAsFixed(2)} KZT');
    
    return transactions;
  }
  
  /// Парсит одну транзакцию из компонентов
  ParsedTransaction? _parseTransaction({
    required String dateStr,
    required String sign,
    required String amountStr,
    required String type,
    required String details,
    required String line,
  }) {
    try {
      // 1. Дата (02.12.25 или 02.12 .25)
      final normalizedDateStr = dateStr.replaceAll(' .', '.').replaceAll('. ', '.').trim();
      DateTime date;
      try {
        date = DateFormat('dd.MM.yy').parse(normalizedDateStr);
      } catch (_) {
        // Пробуем парсить вручную
        final parts = normalizedDateStr.split('.');
        if (parts.length == 3) {
          final day = int.parse(parts[0].trim());
          final month = int.parse(parts[1].trim());
          final yearStr = parts[2].trim();
          final year = yearStr.length == 2 ? 2000 + int.parse(yearStr) : int.parse(yearStr);
          date = DateTime(year, month, day);
        } else {
          return null;
        }
      }

      // 2. Знак и Сумма
      // Чистим сумму: убираем все пробелы (включая неразрывные), меняем запятую на точку
      // Также убираем возможные разделители тысяч
      String cleanAmountStr = amountStr
          .replaceAll(' ', '')
          .replaceAll('\u00A0', '') // Неразрывный пробел
          .replaceAll('\u2009', '') // Тонкий пробел
          .replaceAll('\u202F', '') // Узкий неразрывный пробел
          .replaceAll(',', '.');
      
      // Если есть несколько точек, оставляем только последнюю (разделитель десятичных)
      final dotCount = cleanAmountStr.split('.').length - 1;
      if (dotCount > 1) {
        final lastDotIndex = cleanAmountStr.lastIndexOf('.');
        cleanAmountStr = cleanAmountStr.substring(0, lastDotIndex).replaceAll('.', '') + 
                       cleanAmountStr.substring(lastDotIndex);
      }
      
      double amount = double.parse(cleanAmountStr);
      
      // Определяем доход или расход
      // В Kaspi: Пополнение - всегда доход, Покупка/Снятие - всегда расход
      // Перевод может быть и доходом (+), и расходом (-)
      final typeLower = type.toLowerCase();
      final isIncome = sign == '+' || 
          typeLower.contains('пополнение') ||
          typeLower.contains('deposit');
      
      // 3. Тип операции (Покупка, Перевод...)
      final typeTrimmed = type.trim();
      
      // 4. Детали (название магазина)
      final detailsTrimmed = details.trim();
      
      // Небольшая очистка деталей (иногда туда попадает мусор)
      final finalDetails = detailsTrimmed.isEmpty ? typeTrimmed : detailsTrimmed; 

      return ParsedTransaction(
        date: date,
        amount: amount, // Храним положительное число, флаг isIncome говорит о знаке
        category: typeTrimmed, // "Покупка", "Перевод" используем как категорию пока что
        title: finalDetails,
        isIncome: isIncome,
      );
    } catch (e) {
      print('⚠️ Ошибка парсинга строки: "$line"\nError: $e');
      return null;
    }
  }
}

/// Топ-уровневая функция для [compute] — парсинг выписки Kaspi вне UI-потока.
List<ParsedTransaction> kaspiParseForIsolate(String rawText) {
  return KaspiStatementParser().parse(rawText);
}

