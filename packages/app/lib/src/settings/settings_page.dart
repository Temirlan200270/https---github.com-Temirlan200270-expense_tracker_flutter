import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ui_components/ui_components.dart';
import 'package:features_expenses/features_expenses.dart';

import '../core/theme/app_theme.dart';
import 'settings_providers.dart';
import 'biometric_providers.dart';
import 'color_scheme_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final appThemeType = ref.watch(appThemeTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings')),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          // Внешний вид
          Text(
            "Внешний вид",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.1, end: 0, duration: 300.ms),
          const SizedBox(height: 10),
          SettingsTile(
            icon: Icons.palette_rounded,
            iconColor: Colors.purple,
            title: tr('theme'),
            subtitle: _getThemeModeLabel(themeMode),
            onTap: () => _showThemeDialog(context, ref),
            animationIndex: 0,
          ),
          SettingsTile(
            icon: Icons.color_lens_rounded,
            iconColor: Colors.blue,
            title: tr('color_scheme'),
            subtitle: _getAppThemeTypeLabel(appThemeType, context.locale),
            onTap: () => _showAppThemeTypeDialog(context, ref),
            animationIndex: 1,
          ),
          SettingsTile(
            icon: Icons.language_rounded,
            iconColor: Colors.indigo,
            title: tr('language'),
            subtitle: _getLocaleLabel(locale ?? context.locale),
            onTap: () => _showLanguageDialog(context, ref),
            animationIndex: 2,
          ),
          SettingsTile(
            icon: Icons.attach_money_rounded,
            iconColor: Colors.green,
            title: tr('default_currency'),
            subtitle: defaultCurrency,
            onTap: () => _showCurrencyDialog(context, ref),
            animationIndex: 3,
          ),
          const SizedBox(height: 24),
          // Данные
          Text(
            "Данные",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 400.ms)
              .slideX(begin: -0.1, end: 0, duration: 300.ms, delay: 400.ms),
          const SizedBox(height: 10),
          SettingsTile(
            icon: Icons.key_rounded,
            iconColor: Colors.orange,
            title: tr('gemini_api_key'),
            subtitle: ref.watch(geminiApiKeyProvider) != null 
                ? tr('gemini_api_key_set') 
                : tr('gemini_api_key_not_set'),
            onTap: () => _showGeminiApiKeyDialog(context, ref),
            animationIndex: 4,
          ),
          SettingsTile(
            icon: Icons.currency_exchange_rounded,
            iconColor: Colors.amber,
            title: tr('exchange_rate_api_key'),
            subtitle: ref.watch(exchangeRateApiKeyProvider) != null 
                ? tr('exchange_rate_api_key_set') 
                : tr('exchange_rate_api_key_not_set'),
            onTap: () => _showExchangeRateApiKeyDialog(context, ref),
            animationIndex: 5,
          ),
          SettingsTile(
            icon: Icons.smart_toy_rounded,
            iconColor: Colors.teal,
            title: tr('gemini_model'),
            subtitle: ref.watch(geminiModelProvider),
            onTap: () => _showGeminiModelDialog(context, ref),
            animationIndex: 6,
          ),
          SettingsTile(
            icon: Icons.cloud_upload_rounded,
            iconColor: Colors.cyan,
            title: tr('backup.title'),
            subtitle: tr('backup.subtitle'),
            onTap: () => context.push('/backup'),
            animationIndex: 7,
          ),
          SettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.red,
            title: tr('delete_all_expenses'),
            subtitle: tr('delete_all_expenses_subtitle'),
            onTap: () => _showDeleteAllDialog(context, ref),
            animationIndex: 8,
          ),
          const SizedBox(height: 24),
          // Безопасность
          Text(
            "Безопасность",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 600.ms)
              .slideX(begin: -0.1, end: 0, duration: 300.ms, delay: 600.ms),
          const SizedBox(height: 10),
          // Биометрия
          Consumer(
            builder: (context, ref, child) {
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

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: Colors.red, size: 22),
                  ),
                  title: Text(
                    tr('biometric.title'),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Switch(
                    value: biometricEnabled && isAvailable,
                    onChanged: isAvailable
                        ? (value) async {
                            final navigatorContext = context;
                            await ref.read(biometricEnabledProvider.notifier).setEnabled(value);
                            if (value) {
                              final service = ref.read(biometricServiceProvider);
                              final success = await service.authenticate(
                                reason: tr('biometric.enable_reason'),
                              );
                              if (!success && navigatorContext.mounted) {
                                await ref.read(biometricEnabledProvider.notifier).setEnabled(false);
                                ScaffoldMessenger.of(navigatorContext).showSnackBar(
                                  SnackBar(content: Text(tr('biometric.enable_failed'))),
                                );
                              }
                            }
                          }
                        : null,
                  ),
                ),
              );
            },
          ),
          // Дополнительный отступ снизу для навигационной панели
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
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
                children: ThemeMode.values.map((mode) {
                  return RadioListTile<ThemeMode>(
                    title: Text(_getThemeModeLabel(mode)),
                    value: mode,
                    groupValue: selected,
                    onChanged: (value) {
                      setState(() => selected = value);
                      Navigator.of(dialogContext).pop(value);
                    },
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
                children: supported.map((locale) {
                  return RadioListTile<Locale>(
                    title: Text(_getLocaleLabel(locale)),
                    value: locale,
                    groupValue: selected,
                    onChanged: (value) {
                      setState(() => selected = value);
                      Navigator.of(dialogContext).pop(value);
                    },
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
                children: currencies.map((currency) {
                  return RadioListTile<String>(
                    title: Text(currency),
                    value: currency,
                    groupValue: selected,
                    onChanged: (value) {
                      setState(() => selected = value);
                      Navigator.of(dialogContext).pop(value);
                    },
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
                children: AppThemeType.values.map((type) {
                  final name = _getAppThemeTypeLabel(type, locale);
                  Color color;
                  switch (type) {
                    case AppThemeType.purple:
                      color = const Color(0xFF6B4CFF); // Neo-bank фиолетовый
                      break;
                    case AppThemeType.green:
                      color = const Color(0xFF4CAF50); // Money зеленый
                      break;
                    case AppThemeType.orange:
                      color = const Color(0xFFFF9800); // Теплый оранжевый
                      break;
                  }
                  
                  return RadioListTile<AppThemeType>(
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
                                ? Border.all(color: Colors.white, width: 2)
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
                    value: type,
                    groupValue: selected,
                    onChanged: (value) {
                      setState(() => selected = value);
                      Navigator.of(dialogContext).pop(value);
                    },
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('delete_all_expenses_success')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('delete_all_expenses_error', args: [e.toString()])),
              backgroundColor: Colors.red,
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

