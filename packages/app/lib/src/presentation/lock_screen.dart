import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/home_layout_shell.dart';
import '../settings/biometric_providers.dart';

/// Экран блокировки с биометрией
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(biometricServiceProvider);
      final success = await service.authenticate(
        reason: tr('biometric.unlock_reason'),
      );

      if (success && mounted) {
        // Успешная аутентификация - закрываем экран блокировки
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() {
          _errorMessage = tr('biometric.auth_failed');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = tr('biometric.auth_error');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biometricTypeName = ref.watch(biometricTypeNameProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(HomeLayoutSpacing.s32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Иконка блокировки
                  Container(
                    padding: const EdgeInsets.all(HomeLayoutSpacing.s24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: HomeLayoutSpacing.s32),

                  // Заголовок
                  Text(
                    tr('biometric.locked'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: HomeLayoutSpacing.s8),

                  // Описание
                  Text(
                    biometricTypeName.when(
                      data: (name) => tr('biometric.unlock_hint', args: [name]),
                      loading: () => tr('biometric.unlock_hint_generic'),
                      error: (_, __) => tr('biometric.unlock_hint_generic'),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: HomeLayoutSpacing.s32),

                  // Сообщение об ошибке
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(HomeLayoutSpacing.s12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.onErrorContainer,
                            size: 20,
                          ),
                          SizedBox(width: HomeLayoutSpacing.s8),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: HomeLayoutSpacing.s24),
                  ],

                  // Кнопка повторной попытки
                  FilledButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint_rounded),
                    label: Text(_isAuthenticating
                        ? tr('biometric.authenticating')
                        : tr('biometric.try_again')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
