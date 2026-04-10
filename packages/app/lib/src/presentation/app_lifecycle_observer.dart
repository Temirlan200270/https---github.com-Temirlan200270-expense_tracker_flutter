import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/biometric_providers.dart';
import 'lock_screen.dart';

/// Провайдер для отслеживания состояния блокировки
final appLockedProvider = StateProvider<bool>((ref) => false);

/// Widget, который отслеживает lifecycle приложения и показывает экран блокировки
class AppLifecycleObserver extends ConsumerStatefulWidget {
  const AppLifecycleObserver({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final biometricEnabled = ref.read(biometricEnabledProvider);
    if (!biometricEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Приложение свернуто - блокируем
      if (mounted) {
        ref.read(appLockedProvider.notifier).state = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      // Приложение развернуто - показываем экран блокировки если нужно
      if (mounted && ref.read(appLockedProvider)) {
        // Небольшая задержка, чтобы UI успел обновиться
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showLockScreen();
          }
        });
      }
    }
  }

  void _showLockScreen() {
    // Показываем экран блокировки поверх всего
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).colorScheme.scrim,
      builder: (context) => const LockScreen(),
    ).then((success) {
      if (success == true) {
        // Успешная аутентификация - разблокируем
        ref.read(appLockedProvider.notifier).state = false;
      }
    });
  }

  bool _hasCheckedInitialAuth = false;

  @override
  Widget build(BuildContext context) {
    // Проверяем биометрию при первом запуске, если включена
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final isLocked = ref.watch(appLockedProvider);

    if (biometricEnabled && !_hasCheckedInitialAuth) {
      _hasCheckedInitialAuth = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appLockedProvider.notifier).state = true;
        _showLockScreen();
      });
    } else if (isLocked && !_hasCheckedInitialAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLockScreen();
      });
    }

    return widget.child;
  }
}

