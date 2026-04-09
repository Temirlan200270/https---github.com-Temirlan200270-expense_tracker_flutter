# Настройка OCR для импорта PDF

## Установка зависимостей

Для работы OCR импорта PDF необходимо установить зависимости:

```bash
cd packages/features_export
flutter pub get
```

Или из корня проекта:

```bash
flutter pub get
```

## Зависимости

- `google_mlkit_text_recognition: ^0.13.0` - Google ML Kit для распознавания текста
- `pdf_render_maintained: ^1.6.0` - Конвертация PDF страниц в изображения (совместимо с новым Android embedding)

## Требования Android

Убедитесь, что в `android/app/build.gradle` установлен `minSdkVersion` не менее **21**:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

## Как это работает

1. PDF файл разбивается на страницы
2. Каждая страница рендерится в изображение (PNG)
3. Google ML Kit распознает текст с изображения
4. Распознанный текст парсится через `KaspiStatementParser`
5. Транзакции сохраняются в базу данных

## Примечания

- OCR работает офлайн (после первой загрузки моделей)
- Распознавание может занять некоторое время для больших PDF
- Точность зависит от качества PDF и шрифтов

