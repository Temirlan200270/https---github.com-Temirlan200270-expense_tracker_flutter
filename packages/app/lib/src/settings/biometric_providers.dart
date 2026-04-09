import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/biometric_service.dart';

/// Провайдер для настройки включения/выключения биометрии
final biometricEnabledProvider = StateNotifierProvider<BiometricEnabledNotifier, bool>((ref) {
  return BiometricEnabledNotifier();
});

class BiometricEnabledNotifier extends StateNotifier<bool> {
  static const String _key = 'biometric_enabled';

  BiometricEnabledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
    state = enabled;
  }
}

/// Провайдер для сервиса биометрии
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Провайдер для проверки доступности биометрии
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return service.isAvailable();
});

/// Провайдер для получения названия типа биометрии
final biometricTypeNameProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return service.getAvailableBiometricName();
});

