import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';
import 'package:features_expenses/features_expenses.dart';

import '../core/theme/app_theme.dart';
import '../home/home_layout_shell.dart';
import 'settings_providers.dart';
import 'biometric_providers.dart';
import 'color_scheme_providers.dart';

/// Включение/выключение биометрии (общая логика для Switch и тапа по строке).
Future<void> applyBiometricSetting(
  BuildContext context,
  WidgetRef ref,
  bool enabled,
) async {
  await ref.read(biometricEnabledProvider.notifier).setEnabled(enabled);
  if (enabled) {
    final service = ref.read(biometricServiceProvider);
    final success = await service.authenticate(
      reason: tr('biometric.enable_reason'),
    );
    if (!success && context.mounted) {
      await ref.read(biometricEnabledProvider.notifier).setEnabled(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('biometric.enable_failed'))),
      );
    }
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final appThemeType = ref.watch(appThemeTypeProvider);

    final cs = Theme.of(context).colorScheme;

    return PrimaryScaffold(
      title: tr('settings'),
      child: ListView(
          padding: EdgeInsets.fromLTRB(
            HomeLayoutSpacing.s20,
            HomeLayoutSpacing.s16,
            HomeLayoutSpacing.s20,
            HomeLayoutSpacing.s8,
          ),
          children: [
          Text(
            tr('settings_section_appearance'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          )
              .animate()
              .fadeIn(duration: AppMotion.standard, curve: AppMotion.curve)
              .slideX(
                begin: -0.06,
                end: 0,
                duration: AppMotion.standard,
                curve: AppMotion.curve,
              ),
          SizedBox(height: HomeLayoutSpacing.s12),
          SettingsTile(
            icon: Icons.palette_rounded,
            iconColor: cs.primary,
            title: tr('theme'),
            subtitle: _getThemeModeLabel(themeMode),
            onTap: () => _showThemeDialog(context, ref),
            animationIndex: 0,
          ),
          SettingsTile(
            icon: Icons.color_lens_rounded,
            iconColor: cs.secondary,
            title: tr('color_scheme'),
            subtitle: _getAppThemeTypeLabel(appThemeType, context.locale),
            onTap: () => _showAppThemeTypeDialog(context, ref),
            animationIndex: 1,
          ),
          SettingsTile(
            icon: Icons.language_rounded,
            iconColor: cs.tertiary,
            title: tr('language'),
            subtitle: _getLocaleLabel(locale ?? context.locale),
            onTap: () => _showLanguageDialog(context, ref),
            animationIndex: 2,
          ),
          SettingsTile(
            icon: Icons.attach_money_rounded,
            iconColor: cs.primary,
            title: tr('default_currency'),
            subtitle: defaultCurrency,
            onTap: () => _showCurrencyDialog(context, ref),
            animationIndex: 3,
          ),
          SizedBox(height: HomeLayoutSpacing.s24),
          Text(
            tr('settings_section_data'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          )
              .animate()
              .fadeIn(
                duration: AppMotion.standard,
                delay: AppMotion.staggerInterval * 4,
                curve: AppMotion.curve,
              )
              .slideX(
                begin: -0.06,
                end: 0,
                duration: AppMotion.standard,
                delay: AppMotion.staggerInterval * 4,
                curve: AppMotion.curve,
              ),
          SizedBox(height: HomeLayoutSpacing.s12),
          SettingsTile(
            icon: Icons.key_rounded,
            iconColor: cs.tertiary,
            title: tr('gemini_api_key'),
            subtitle: ref.watch(geminiApiKeyProvider) != null 
                ? tr('gemini_api_key_set') 
                : tr('gemini_api_key_not_set'),
            onTap: () => _showGeminiApiKeyDialog(context, ref),
            animationIndex: 4,
          ),
          SettingsTile(
            icon: Icons.currency_exchange_rounded,
            iconColor: cs.secondary,
            title: tr('exchange_rate_api_key'),
            subtitle: ref.watch(exchangeRateApiKeyProvider) != null 
                ? tr('exchange_rate_api_key_set') 
                : tr('exchange_rate_api_key_not_set'),
            onTap: () => _showExchangeRateApiKeyDialog(context, ref),
            animationIndex: 5,
          ),
          SettingsTile(
            icon: Icons.smart_toy_rounded,
            iconColor: cs.tertiary,
            title: tr('gemini_model'),
            subtitle: ref.watch(geminiModelProvider),
            onTap: () => _showGeminiModelDialog(context, ref),
            animationIndex: 6,
          ),
          SettingsTile(
            icon: Icons.cloud_upload_rounded,
            iconColor: cs.primary,
            title: tr('backup.title'),
            subtitle: tr('backup.subtitle'),
            onTap: () => context.push('/backup'),
            animationIndex: 7,
          ),
          SettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: cs.error,
            title: tr('delete_all_expenses'),
            subtitle: tr('delete_all_expenses_subtitle'),
            onTap: () => _showDeleteAllDialog(context, ref),
            animationIndex: 8,
          ),
          SizedBox(height: HomeLayoutSpacing.s24),
          Text(
            tr('settings_section_security'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          )
              .animate()
              .fadeIn(
                duration: AppMotion.standard,
                delay: AppMotion.staggerInterval * 8,
                curve: AppMotion.curve,
              )
              .slideX(
                begin: -0.06,
                end: 0,
                duration: AppMotion.standard,
                delay: AppMotion.staggerInterval * 8,
                curve: AppMotion.curve,
              ),
          SizedBox(height: HomeLayoutSpacing.s12),
          Consumer(
            builder: (context, ref, _) {
              final biometricEnabled = ref.watch(biometricEnabledProvider);
              final biometricAvailable = ref.watch(biometricAvailableProvider);
              final biometricTypeName = ref.watch(biometricTypeNameProvider);

              final isAvailable = biometricAvailable.valueOrNull ?? false;
              final subtitle = biometricAvailable.when(
                data: (available) {
                  if (!available) {
                    return tr('biometric.not_available');
                  }
                  return biometricTypeName.when(
                    data: (name) => '$name ${tr('biometric.available')}',
                    loading: () => tr('biometric.checking'),
                    error: (_, __) => tr('biometric.not_available'),
                  );
                },
                loading: () => tr('biometric.checking'),
                error: (_, __) => tr('biometric.not_available'),
              );

              final on = biometricEnabled && isAvailable;

              return SettingsTile(
                icon: Icons.fingerprint_rounded,
                iconColor: cs.error,
                title: tr('biometric.title'),
                subtitle: subtitle,
                animationIndex: 9,
                onTap: isAvailable
                    ? () => unawaited(
                          applyBiometricSetting(context, ref, !on),
                        )
                    : () {},
                trailing: Switch(
                  value: on,
                  onChanged: isAvailable
                      ? (value) => unawaited(
                            applyBiometricSetting(context, ref, value),
                          )
                      : null,
                ),
              );
            },
          ),
          // Дополнительный отступ снизу для навигационной панели
          SizedBox(height: MediaQuery.of(context).padding.bottom + HomeLayoutSpacing.s16),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return tr('theme_light');
      case ThemeMode.dark:
        return tr('theme_dark');
      case ThemeMode.system:
        return tr('theme_system');
    }
  }

  String _getLocaleLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }

  String _getAppThemeTypeLabel(AppThemeType type, Locale locale) {
    switch (type) {
      case AppThemeType.purple:
        return locale.languageCode == 'ru' ? 'Neo-bank (Фиолетовый)' : 'Neo-bank (Purple)';
      case AppThemeType.green:
        return locale.languageCode == 'ru' ? 'Money (Зелёный)' : 'Money (Green)';
      case AppThemeType.orange:
        return locale.languageCode == 'ru' ? 'Тёплая (Оранжевый)' : 'Warm (Orange)';
    }
  }

  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          ThemeMode? selected = current;
          return AlertDialog(
            title: Text(tr('theme')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ThemeMode.values.map<Widget>((mode) {
                  return RadioListTile<ThemeMode>(
                    value: mode,
                    groupValue: selected,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        setState(() => selected = value);
                        Navigator.of(dialogContext).pop(value);
                      }
                    },
                    title: Text(_getThemeModeLabel(mode)),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(result);
    }
  }

  Future<void> _showLanguageDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(localeProvider) ?? context.locale;
    final supported = context.supportedLocales;
    final result = await showDialog<Locale>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          Locale? selected = current;
          return AlertDialog(
            title: Text(tr('language')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: supported.map<Widget>((locale) {
                  return RadioListTile<Locale>(
                    value: locale,
                    groupValue: selected,
                    onChanged: (Locale? value) {
                      if (value != null) {
                        setState(() => selected = value);
                        Navigator.of(dialogContext).pop(value);
                      }
                    },
                    title: Text(_getLocaleLabel(locale)),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
    if (result != null && context.mounted) {
      await ref.read(localeProvider.notifier).setLocale(result);
      context.setLocale(result);
    }
  }

  Future<void> _showCurrencyDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(defaultCurrencyProvider);
    final currencies = ['KZT', 'RUB', 'USD', 'EUR', 'GBP', 'JPY', 'CNY'];
    
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          String? selected = current;
          return AlertDialog(
            title: Text(tr('default_currency')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: currencies.map<Widget>((currency) {
                  return RadioListTile<String>(
                    value: currency,
                    groupValue: selected,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => selected = value);
                        Navigator.of(dialogContext).pop(value);
                      }
                    },
                    title: Text(currency),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      await ref.read(defaultCurrencyProvider.notifier).setCurrency(result);
    }
  }

  Future<void> _showAppThemeTypeDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(appThemeTypeProvider);
    final locale = context.locale;
    
    final result = await showDialog<AppThemeType>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          AppThemeType? selected = current;
          return AlertDialog(
            title: Text(tr('color_scheme')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppThemeType.values.map<Widget>((type) {
                  final name = _getAppThemeTypeLabel(type, locale);
                  final color = AppTheme.brandSeedColor(type);
                  final dialogCs = Theme.of(context).colorScheme;

                  return RadioListTile<AppThemeType>(
                    value: type,
                    groupValue: selected,
                    onChanged: (AppThemeType? value) {
                      if (value != null) {
                        setState(() => selected = value);
                        Navigator.of(dialogContext).pop(value);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selected == type
                                ? Border.all(color: dialogCs.primary, width: 2)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      await ref.read(appThemeTypeProvider.notifier).setThemeType(result);
    }
  }

  Future<void> _showGeminiApiKeyDialog(BuildContext context, WidgetRef ref) async {
    final currentKey = ref.read(geminiApiKeyProvider);
    final controller = TextEditingController(text: currentKey ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('gemini_api_key')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('gemini_api_key_description')),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: tr('gemini_api_key'),
                hintText: 'AIza...',
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            Text(
              tr('gemini_api_key_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          if (currentKey != null)
            TextButton(
              onPressed: () async {
                await ref.read(geminiApiKeyProvider.notifier).setApiKey(null);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(tr('delete')),
            ),
          TextButton(
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                await ref.read(geminiApiKeyProvider.notifier).setApiKey(newKey);
              } else {
                await ref.read(geminiApiKeyProvider.notifier).setApiKey(null);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showExchangeRateApiKeyDialog(BuildContext context, WidgetRef ref) async {
    final currentKey = ref.read(exchangeRateApiKeyProvider);
    final controller = TextEditingController(text: currentKey ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('exchange_rate_api_key')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('exchange_rate_api_key_description')),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: tr('exchange_rate_api_key'),
                hintText: 'твой_ключ_здесь',
                border: const OutlineInputBorder(),
              ),
              obscureText: false,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            Text(
              tr('exchange_rate_api_key_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          if (currentKey != null)
            TextButton(
              onPressed: () async {
                await ref.read(exchangeRateApiKeyProvider.notifier).setApiKey(null);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(tr('delete')),
            ),
          TextButton(
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                await ref.read(exchangeRateApiKeyProvider.notifier).setApiKey(newKey);
              } else {
                await ref.read(exchangeRateApiKeyProvider.notifier).setApiKey(null);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showGeminiModelDialog(BuildContext context, WidgetRef ref) async {
    final currentModel = ref.read(geminiModelProvider);
    final controller = TextEditingController(text: currentModel);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('gemini_model')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('gemini_model_description')),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: tr('gemini_model'),
                hintText: 'gemini-2.5-flash',
                border: const OutlineInputBorder(),
                helperText: tr('gemini_model_hint'),
              ),
              autocorrect: false,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModelChip(
                  label: 'gemini-2.0-flash-exp',
                  controller: controller,
                ),
                _ModelChip(
                  label: 'gemini-2.5-flash',
                  controller: controller,
                ),
                _ModelChip(
                  label: 'gemini-2.5-pro',
                  controller: controller,
                ),
                _ModelChip(
                  label: 'gemini-1.5-flash',
                  controller: controller,
                ),
                _ModelChip(
                  label: 'gemini-1.5-pro',
                  controller: controller,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final newModel = controller.text.trim();
              if (newModel.isNotEmpty) {
                await ref.read(geminiModelProvider.notifier).setModel(newModel);
              } else {
                await ref.read(geminiModelProvider.notifier).setModel('gemini-2.5-flash');
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAllDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_all_expenses_title')),
        content: Text(tr('delete_all_expenses_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(expensesRepositoryProvider);
        await repo.deleteAllExpenses();

        if (context.mounted) {
          final snackCs = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: snackCs.primaryContainer,
              content: Text(
                tr('delete_all_expenses_success'),
                style: TextStyle(color: snackCs.onPrimaryContainer),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final snackCs = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: snackCs.errorContainer,
              content: Text(
                tr('delete_all_expenses_error', args: [e.toString()]),
                style: TextStyle(color: snackCs.onErrorContainer),
              ),
            ),
          );
        }
      }
    }
  }
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        controller.text = label;
      },
    );
  }
}

