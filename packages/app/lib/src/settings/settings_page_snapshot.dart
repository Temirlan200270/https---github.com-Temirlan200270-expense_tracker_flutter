import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'color_scheme_providers.dart';
import 'settings_providers.dart';

/// Неизменяемый снимок значений для экрана настроек: один проход [watch],
/// дальше передаётся вниз без точечных [ref.watch] на плитках.
@immutable
class SettingsPageSnapshot {
  const SettingsPageSnapshot({
    required this.themeMode,
    required this.savedLocale,
    required this.defaultCurrency,
    required this.appThemeType,
    required this.reduceMotion,
    required this.hasGeminiApiKey,
    required this.hasExchangeRateApiKey,
    required this.geminiModelId,
  });

  final ThemeMode themeMode;
  final Locale? savedLocale;
  final String defaultCurrency;
  final AppThemeType appThemeType;
  final bool reduceMotion;
  final bool hasGeminiApiKey;
  final bool hasExchangeRateApiKey;
  final String geminiModelId;

  static SettingsPageSnapshot watch(WidgetRef ref) {
    return SettingsPageSnapshot(
      themeMode: ref.watch(themeModeProvider),
      savedLocale: ref.watch(localeProvider),
      defaultCurrency: ref.watch(defaultCurrencyProvider),
      appThemeType: ref.watch(appThemeTypeProvider),
      reduceMotion: ref.watch(reduceMotionProvider),
      hasGeminiApiKey: ref.watch(geminiApiKeyProvider) != null,
      hasExchangeRateApiKey: ref.watch(exchangeRateApiKeyProvider) != null,
      geminiModelId: ref.watch(geminiModelProvider),
    );
  }
}
