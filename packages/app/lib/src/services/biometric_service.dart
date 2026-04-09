import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Сервис для работы с биометрией (FaceID, Fingerprint, PIN)
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Проверяет, доступна ли биометрия на устройстве
  Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable || isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Получить список доступных типов биометрии
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Аутентификация через биометрию
  /// Возвращает true, если аутентификация успешна
  Future<bool> authenticate({
    String reason = 'Подтвердите свою личность',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Разрешаем использовать PIN/Password как fallback
        ),
      );
    } on PlatformException catch (e) {
      // Обработка ошибок платформы
      if (e.code == 'NotAvailable') {
        return false;
      }
      if (e.code == 'NotEnrolled') {
        return false;
      }
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Проверяет, заблокирована ли биометрия (слишком много неудачных попыток)
  Future<bool> isLockedOut() async {
    try {
      final available = await getAvailableBiometrics();
      // Если биометрия недоступна, считаем что не заблокирована
      if (available.isEmpty) return false;

      // Пытаемся аутентифицироваться, но с stickyAuth = false
      // Если вернёт ошибку LockedOut, значит заблокирована
      try {
        await _localAuth.authenticate(
          localizedReason: 'Проверка блокировки',
          options: const AuthenticationOptions(
            useErrorDialogs: false,
            stickyAuth: false,
            biometricOnly: true,
          ),
        );
        return false;
      } on PlatformException catch (e) {
        return e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut';
      }
    } catch (e) {
      return false;
    }
  }

  /// Получить понятное название типа биометрии
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Отпечаток пальца';
      case BiometricType.strong:
        return 'Сильная биометрия';
      case BiometricType.weak:
        return 'Слабая биометрия';
      case BiometricType.iris:
        return 'Радужка глаза';
    }
  }

  /// Получить общее название доступной биометрии для UI
  Future<String> getAvailableBiometricName() async {
    final types = await getAvailableBiometrics();
    if (types.isEmpty) return 'Биометрия недоступна';

    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    }
    if (types.contains(BiometricType.fingerprint)) {
      return 'Отпечаток пальца';
    }
    if (types.contains(BiometricType.iris)) {
      return 'Радужка глаза';
    }

    return 'Биометрия';
  }
}

