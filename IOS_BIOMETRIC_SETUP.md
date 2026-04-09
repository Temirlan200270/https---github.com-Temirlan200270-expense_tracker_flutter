# Настройка биометрии для iOS

Когда будет настроен iOS проект, добавьте в файл `ios/Runner/Info.plist` следующую настройку:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Используйте Face ID для защиты ваших финансовых данных</string>
```

## Где добавить

Откройте файл `ios/Runner/Info.plist` и добавьте ключ `NSFaceIDUsageDescription` внутри тега `<dict>`, например:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... другие ключи ... -->
    
    <key>NSFaceIDUsageDescription</key>
    <string>Используйте Face ID для защиты ваших финансовых данных</string>
    
    <!-- ... остальные ключи ... -->
</dict>
</plist>
```

## Примечание

Этот ключ обязателен для использования Face ID в iOS. Без него приложение не сможет запросить аутентификацию через Face ID.

