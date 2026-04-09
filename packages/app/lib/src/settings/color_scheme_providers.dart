import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import 'settings_providers.dart';

/// Провайдер для выбранной цветовой схемы (AppThemeType)
final appThemeTypeProvider = StateNotifierProvider<AppThemeTypeNotifier, AppThemeType>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppThemeTypeNotifier(prefs);
});

class AppThemeTypeNotifier extends StateNotifier<AppThemeType> {
  AppThemeTypeNotifier(this._prefs) : super(AppThemeType.purple) {
    _loadThemeType();
  }

  final SharedPreferences _prefs;
  static const String _key = 'app_theme_type';

  Future<void> _loadThemeType() async {
    final saved = _prefs.getInt(_key);
    if (saved != null && saved < AppThemeType.values.length) {
      state = AppThemeType.values[saved];
    }
  }

  Future<void> setThemeType(AppThemeType type) async {
    state = type;
    await _prefs.setInt(_key, type.index);
  }
}

