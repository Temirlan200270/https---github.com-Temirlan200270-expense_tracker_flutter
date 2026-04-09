// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// Сервис для распознавания текста из PDF с использованием AI API (Google Gemini)
class AiOcrService {
  final WidgetRef? ref;

  AiOcrService({this.ref});

  /// Распознать текст из PDF файла через Google Gemini API
  ///
  /// [apiKey] - API ключ Gemini. Если не указан, будет использован из переменной окружения.
  /// [model] - Модель Gemini. Если не указана, будет использована из настроек.
  Future<String?> recognizePdf(File pdfFile,
      {String? apiKey, String? model}) async {
    // Получаем API ключ: сначала из параметра, потом из провайдера, потом из AppConfig
    if (apiKey == null || apiKey.isEmpty) {
      if (ref != null) {
        apiKey = ref!.read(geminiApiKeyProvider);
      }
      if (apiKey == null || apiKey.isEmpty) {
        apiKey = AppConfig.geminiApiKey;
      }
    }

    // Получаем модель из параметра, настроек или используем дефолтную
    String? geminiModel = model;
    if (geminiModel == null || geminiModel.isEmpty) {
      if (ref != null) {
        geminiModel = ref!.read(geminiModelProvider);
      }
      geminiModel ??= 'gemini-2.5-flash';
    }

    print(
        '🔑 Используется API ключ: ${apiKey != null && apiKey.isNotEmpty ? '${apiKey.substring(0, 4)}...' : 'НЕ УСТАНОВЛЕН'}');
    print('🤖 Используется модель: $geminiModel');

    if (apiKey == null || apiKey.isEmpty) {
      print(
          '⚠️ Gemini API ключ не настроен. Установите его в настройках приложения.');
      return null;
    }

    // После проверки apiKey гарантированно не null
    // После строки 42 geminiModel гарантированно не null
    final finalModel = geminiModel;
    final finalApiKey = apiKey;

    PdfDocument? doc;
    try {
      // Открываем PDF документ
      doc = await PdfDocument.openFile(pdfFile.path);
      final pages = doc.pages;
      final pageCount = pages.length;
      final StringBuffer fullText = StringBuffer();

      print('📄 Начало AI OCR обработки. Страниц: $pageCount');

      // Обрабатываем все страницы параллельно для ускорения
      final pageResults = await Future.wait(
        List.generate(
            pageCount,
            (i) => _processPageAsync(
                  pages[i],
                  i + 1,
                  pageCount,
                  finalApiKey,
                  finalModel,
                )),
      );

      // Собираем результаты
      for (final result in pageResults) {
        if (result != null && result.isNotEmpty) {
          fullText.writeln(result);
        }
      }

      final result = fullText.toString();
      print('📝 Итого распознано: ${result.length} символов');
      return result.isEmpty ? null : result;
    } catch (e, stackTrace) {
      print('❌ Ошибка AI OCR: $e');
      print('Stack trace: $stackTrace');
      return null;
    } finally {
      await doc?.dispose();
    }
  }

  /// Асинхронная обработка одной страницы
  Future<String?> _processPageAsync(
    PdfPage page,
    int pageNumber,
    int totalPages,
    String apiKey,
    String model,
  ) async {
    PdfImage? pageImage;
    try {
      print('🔍 Обработка страницы $pageNumber из $totalPages через AI...');

      // Рендерим страницу в изображение с хорошим качеством (DPI 300)
      final dpi = 300.0;
      final fullWidth = (page.width * dpi / 72).toInt();
      final fullHeight = (page.height * dpi / 72).toInt();

      pageImage = await page.render(
        width: fullWidth,
        height: fullHeight,
        fullWidth: fullWidth.toDouble(),
        fullHeight: fullHeight.toDouble(),
      );

      if (pageImage == null) {
        print('⚠️ Не удалось отрендерить страницу $pageNumber');
        return null;
      }

      // Сохраняем изображение во временный файл
      final tempDir = await getTemporaryDirectory();
      final imagePath = '${tempDir.path}/pdf_page_$pageNumber.png';
      final imageFile = File(imagePath);

      try {
        final rgbaBytes = pageImage.pixels;
        if (rgbaBytes.isEmpty) {
          print(
              '⚠️ Не удалось получить байты изображения для страницы $pageNumber');
          return null;
        }

        // Создаем изображение из RGBA байтов используя Image.fromBytes
        final width = pageImage.width.toInt();
        final height = pageImage.height.toInt();
        final rowStride = width * 4; // 4 байта на пиксель (RGBA)

        final image = img.Image.fromBytes(
          width: width,
          height: height,
          bytes: rgbaBytes.buffer,
          rowStride: rowStride,
          numChannels: 4, // RGBA
        );

        // Конвертируем в PNG и сохраняем
        final pngBytes = img.encodePng(image);
        await imageFile.writeAsBytes(pngBytes);

        print(
            '✅ Страница $pageNumber: изображение сохранено (${pngBytes.length} байт)');
      } catch (e, stackTrace) {
        print('❌ Ошибка конвертации изображения страницы $pageNumber: $e');
        print('Stack trace: $stackTrace');
        return null;
      }

      // Отправляем изображение в Gemini API с retry
      final recognizedText = await _recognizeImageWithGeminiWithRetry(
          imageFile, apiKey, model,
          maxRetries: 3);

      // Удаляем временный файл
      try {
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (_) {
        // Игнорируем ошибки удаления
      }

      if (recognizedText != null && recognizedText.isNotEmpty) {
        print(
            '✅ Страница $pageNumber: распознано ${recognizedText.length} символов');
        return recognizedText;
      } else {
        print('⚠️ Страница $pageNumber: текст не распознан');
        return null;
      }
    } catch (e) {
      print('❌ Ошибка обработки страницы $pageNumber: $e');
      return null;
    } finally {
      pageImage?.dispose();
    }
  }

  /// Распознать текст из изображения через Google Gemini API с retry
  Future<String?> _recognizeImageWithGeminiWithRetry(
    File imageFile,
    String apiKey,
    String model, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result =
            await _recognizeImageWithGemini(imageFile, apiKey, model);
        if (result != null) {
          return result;
        }

        // Если получили 503, ждем и повторяем
        if (attempt < maxRetries) {
          print(
              '⚠️ Попытка $attempt не удалась, повтор через ${retryDelay.inSeconds}с...');
          await Future.delayed(
              retryDelay * attempt); // Экспоненциальная задержка
        }
      } catch (e) {
        if (attempt < maxRetries) {
          print(
              '⚠️ Ошибка на попытке $attempt: $e, повтор через ${retryDelay.inSeconds}с...');
          await Future.delayed(retryDelay * attempt);
        } else {
          rethrow;
        }
      }
    }
    return null;
  }

  /// Распознать текст из изображения через Google Gemini API
  Future<String?> _recognizeImageWithGemini(
      File imageFile, String apiKey, String model) async {
    try {
      // Читаем изображение и конвертируем в base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Формируем запрос к Gemini API с выбранной моделью
      final url = Uri.parse(
          '${AppConfig.geminiApiBaseUrl}/models/$model:generateContent?key=$apiKey');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Распознай весь текст с этого изображения выписки из банка Kaspi. Верни только текст, без дополнительных комментариев. Сохрани форматирование (даты, суммы, категории).'
              },
              {
                'inline_data': {'mime_type': 'image/png', 'data': base64Image}
              }
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 8000, // Увеличено для больших страниц
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = jsonResponse['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            return text;
          }
        }
        return null;
      } else if (response.statusCode == 503) {
        // Специальная обработка для 503 - пробрасываем для retry
        print('❌ Ошибка Gemini API: ${response.statusCode} - ${response.body}');
        throw Exception('Gemini API overloaded (503)');
      } else {
        print('❌ Ошибка Gemini API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Ошибка при вызове Gemini API: $e');
      return null;
    }
  }
}
