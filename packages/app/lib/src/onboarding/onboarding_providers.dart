import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingCompletedProvider = StateNotifierProvider<OnboardingCompletedNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingCompletedNotifier(prefs);
});

class OnboardingCompletedNotifier extends StateNotifier<bool> {
  OnboardingCompletedNotifier(this._prefs) : super(false) {
    _loadOnboardingStatus();
  }

  final SharedPreferences _prefs;
  static const String _key = 'onboarding_completed';

  void _loadOnboardingStatus() {
    state = _prefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    state = true;
    await _prefs.setBool(_key, true);
  }
}

