# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Drift/SQLite
-keep class drift.** { *; }
-keep class sqlite3_flutter_libs.** { *; }

# Keep Riverpod
-keep class riverpod.** { *; }

# Keep ML Kit
-keep class com.google.mlkit.** { *; }

# Keep share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep printing
-keep class net.nfet.flutter.printing.** { *; }

# Play Core (split install / deferred components) — классы подтягиваются embedding’ом Flutter,
# в обычном APK их нет; R8 иначе падает на minifyRelease.
-dontwarn com.google.android.play.core.**

# ML Kit Text Recognition — опциональные скрипты (CJK, Devanagari и т.д.); в classpath только латиница.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
