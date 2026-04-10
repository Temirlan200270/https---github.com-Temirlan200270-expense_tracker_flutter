import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_providers.dart' show sharedPreferencesProvider;

/// Показ интерактивного тура по главному экрану после онбординга (флаг в SharedPreferences).
final homeWalkthroughPendingProvider =
    StateNotifierProvider<HomeWalkthroughPendingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HomeWalkthroughPendingNotifier(prefs);
});

class HomeWalkthroughPendingNotifier extends StateNotifier<bool> {
  HomeWalkthroughPendingNotifier(this._prefs) : super(false) {
    _load();
  }

  final SharedPreferences _prefs;
  static const String _key = 'home_walkthrough_pending';

  void _load() {
    state = _prefs.getBool(_key) ?? false;
  }

  Future<void> markPending() async {
    state = true;
    await _prefs.setBool(_key, true);
  }

  Future<void> clearPending() async {
    state = false;
    await _prefs.setBool(_key, false);
  }
}
