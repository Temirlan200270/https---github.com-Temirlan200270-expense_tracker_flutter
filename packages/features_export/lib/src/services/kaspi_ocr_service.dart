// ignore_for_file: avoid_print

import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

class KaspiOcrService {
  late final TextRecognizer _textRecognizer;

  KaspiOcrService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Главный метод: Распознать текст из PDF файла
  Future<String?> recognizePdf(File pdfFile) async {
    PdfDocument? doc;
    try {
      // Открываем PDF документ через pdfrx
      doc = await PdfDocument.openFile(pdfFile.path);
      final pages = doc.pages;
      final pageCount = pages.length;
      final StringBuffer fullText = StringBuffer();

      print('📄 Начало OCR обработки. Страниц: $pageCount');

      // Обрабатываем все страницы параллельно для ускорения
      final pageResults = await Future.wait(
        List.generate(pageCount, (i) => _processPageAsync(
          pages[i],
          i + 1,
          pageCount,
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
      print('❌ Ошибка OCR: $e');
      print('Stack trace: $stackTrace');
      return null;
    } finally {
      // Освобождаем ресурсы документа
      await doc?.dispose();
    }
  }

  /// Асинхронная обработка одной страницы
  Future<String?> _processPageAsync(
    PdfPage page,
    int pageNumber,
    int totalPages,
  ) async {
    PdfImage? pageImage;
    try {
      print('🔍 Обработка страницы $pageNumber из $totalPages...');

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

      // Сохраняем во временный файл
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/pdf_page_$pageNumber.png';
      final file = File(path);

      // Конвертируем RGBA пиксели в PNG изображение
      try {
        final rgbaBytes = pageImage.pixels;
        if (rgbaBytes.isEmpty) {
          print(
              '⚠️ Не удалось получить байты из PdfImage страницы $pageNumber');
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
        await file.writeAsBytes(pngBytes);
      } catch (e) {
        print('❌ Ошибка сохранения изображения страницы $pageNumber: $e');
        return null;
      }

      // Распознаем текст из сохраненного файла
      final inputImage = InputImage.fromFilePath(path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Удаляем временный файл
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Игнорируем ошибки удаления временных файлов
      }

      if (recognizedText.text.isNotEmpty) {
        print(
            '✅ Страница $pageNumber: распознано ${recognizedText.text.length} символов');
        return recognizedText.text;
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

  void dispose() {
    _textRecognizer.close();
  }
}
