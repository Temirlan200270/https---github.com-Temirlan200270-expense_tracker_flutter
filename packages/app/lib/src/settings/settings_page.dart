import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ui_components/ui_components.dart';
import 'package:features_expenses/features_expenses.dart';

import '../navigation/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../home/home_layout_shell.dart';
import 'settings_constants.dart';
import 'settings_input_dialogs.dart';
import 'settings_page_snapshot.dart';
import 'settings_providers.dart';
import 'settings_selection_dialog.dart';
import 'biometric_providers.dart';
import 'color_scheme_providers.dart';

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
    final SettingsPageSnapshot snapshot = SettingsPageSnapshot.watch(ref);

    final cs = Theme.of(context).colorScheme;
    var idx = 0;

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
          // ── Appearance ──
          _sectionHeader(context, 'settings_section_appearance', delay: 0),
          SizedBox(height: HomeLayoutSpacing.s12),
          SettingsTile(
            icon: Icons.palette_rounded,
            iconColor: cs.primary,
            title: tr('theme'),
            subtitle: _getThemeModeLabel(snapshot.themeMode),
            onTap: () => _showThemeDialog(context, ref),
            animationIndex: idx++,
          ),
          SettingsTile(
            icon: Icons.color_lens_rounded,
            iconColor: cs.secondary,
            title: tr('color_scheme'),
            subtitle: _getAppThemeTypeLabel(snapshot.appThemeType),
            onTap: () => _showAppThemeTypeDialog(context, ref),
            animationIndex: idx++,
          ),
          SettingsTile(
            icon: Icons.language_rounded,
            iconColor: cs.tertiary,
            title: tr('language'),
            subtitle:
                _getLocaleLabel(snapshot.savedLocale ?? context.locale),
            onTap: () => _showLanguageDialog(context, ref),
            animationIndex: idx++,
          ),
          SettingsTile(
            icon: Icons.attach_money_rounded,
            iconColor: cs.primary,
            title: tr('default_currency'),
            subtitle: snapshot.defaultCurrency,
            onTap: () => _showCurrencyDialog(context, ref),
            animationIndex: idx++,
          ),
          SizedBox(height: HomeLayoutSpacing.s24),

          // ── Data ──
          _sectionHeader(context, 'settings_section_data', delay: idx),
          SizedBox(height: HomeLayoutSpacing.s12),
          SettingsTile(
            icon: Icons.cloud_upload_rounded,
            iconColor: cs.primary,
            title: tr('backup.title'),
            subtitle: tr('backup.subtitle'),
            onTap: () => context.push(AppRoutes.backup),
            animationIndex: idx++,
          ),
          SizedBox(height: HomeLayoutSpacing.s24),

          // ── Integrations ──
          _sectionHeader(context, 'settings_section_integrations', delay: idx),
          SizedBox(height: HomeLayoutSpacing.s12),
          SettingsTile(
            icon: Icons.key_rounded,
            iconColor: cs.tertiary,
            title: tr('gemini_api_key'),
            subtitle: snapshot.hasGeminiApiKey
                ? tr('gemini_api_key_set')
                : tr('gemini_api_key_not_set'),
            onTap: () => showGeminiApiKeyEditor(context, ref),
            animationIndex: idx++,
          ),
          SettingsTile(
            icon: Icons.currency_exchange_rounded,
            iconColor: cs.secondary,
            title: tr('exchange_rate_api_key'),
            subtitle: snapshot.hasExchangeRateApiKey
                ? tr('exchange_rate_api_key_set')
                : tr('exchange_rate_api_key_not_set'),
            onTap: () => showExchangeRateApiKeyEditor(context, ref),
            animationIndex: idx++,
          ),
          SettingsTile(
            icon: Icons.smart_toy_rounded,
            iconColor: cs.tertiary,
            title: tr('gemini_model'),
            subtitle: snapshot.geminiModelId,
            onTap: () => showGeminiModelEditor(context, ref),
            animationIndex: idx++,
          ),
          SizedBox(height: HomeLayoutSpacing.s24),

          // ── Accessibility ──
          _sectionHeader(context, 'settings_section_accessibility', delay: idx),
          SizedBox(height: HomeLayoutSpacing.s12),
          SettingsTile(
            icon: Icons.animation_rounded,
            iconColor: cs.secondary,
            title: tr('reduce_motion'),
            subtitle: tr('reduce_motion_description'),
            animationIndex: idx++,
            onTap: () => ref
                .read(reduceMotionProvider.notifier)
                .setEnabled(!snapshot.reduceMotion),
            trailing: Switch(
              value: snapshot.reduceMotion,
              onChanged: (value) =>
                  ref.read(reduceMotionProvider.notifier).setEnabled(value),
            ),
          ),
          SizedBox(height: HomeLayoutSpacing.s24),

          // ── Security ──
          _sectionHeader(context, 'settings_section_security', delay: idx),
          SizedBox(height: HomeLayoutSpacing.s12),
          Consumer(
            builder: (context, ref, _) {
              final biometricEnabled = ref.watch(biometricEnabledProvider);
              final biometricAvailable = ref.watch(biometricAvailableProvider);
              final biometricTypeName = ref.watch(biometricTypeNameProvider);

              final isAvailable = biometricAvailable.valueOrNull ?? false;
              final subtitle = biometricAvailable.when(
                data: (available) {
                  if (!available) return tr('biometric.not_available');
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
                iconColor: cs.primary,
                title: tr('biometric.title'),
                subtitle: subtitle,
                animationIndex: idx++,
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
          SizedBox(height: HomeLayoutSpacing.s24),

          // ── Danger Zone ──
          _sectionHeader(context, 'settings_section_danger',
              delay: idx, color: cs.error),
          SizedBox(height: HomeLayoutSpacing.s12),
          SettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: cs.error,
            title: tr('delete_all_expenses'),
            subtitle: tr('delete_all_expenses_subtitle'),
            onTap: () => _showDeleteAllDialog(context, ref),
            animationIndex: idx++,
          ),
          SizedBox(height: HomeLayoutSpacing.s24),

          // ── About ──
          _sectionHeader(context, 'settings_section_about', delay: idx),
          SizedBox(height: HomeLayoutSpacing.s12),
          SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: cs.onSurfaceVariant,
            title: tr('about_version'),
            subtitle: '',
            onTap: () {},
            animationIndex: idx++,
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) {
                final version = snap.data?.version ?? '...';
                final build = snap.data?.buildNumber ?? '';
                final display =
                    build.isNotEmpty ? '$version ($build)' : version;
                return Text(
                  display,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                );
              },
            ),
          ),
          SettingsTile(
            icon: Icons.description_outlined,
            iconColor: cs.onSurfaceVariant,
            title: tr('about_licenses'),
            subtitle: '',
            onTap: () => showLicensePage(
              context: context,
              applicationName: tr('app_title'),
            ),
            animationIndex: idx++,
          ),

          SizedBox(
              height: MediaQuery.of(context).padding.bottom +
                  HomeLayoutSpacing.s16),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String key, {
    required int delay,
    Color? color,
  }) {
    return Text(
      tr(key),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
    )
        .animate()
        .fadeIn(
          duration: AppMotion.standard,
          delay: AppMotion.staggerInterval * delay,
          curve: AppMotion.curve,
        )
        .slideX(
          begin: -0.06,
          end: 0,
          duration: AppMotion.standard,
          delay: AppMotion.staggerInterval * delay,
          curve: AppMotion.curve,
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
        return tr('locale_ru');
      case 'en':
        return tr('locale_en');
      default:
        return locale.languageCode;
    }
  }

  String _getAppThemeTypeLabel(AppThemeType type) {
    switch (type) {
      case AppThemeType.purple:
        return tr('theme_purple');
      case AppThemeType.green:
        return tr('theme_green');
      case AppThemeType.orange:
        return tr('theme_orange');
    }
  }

  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref) async {
    final ThemeMode current = ref.read(themeModeProvider);
    final ThemeMode? result = await showSelectionDialog<ThemeMode>(
      context: context,
      title: tr('theme'),
      current: current,
      items: ThemeMode.values
          .map(
            (ThemeMode mode) => SelectionItem<ThemeMode>(
              value: mode,
              title: Text(_getThemeModeLabel(mode)),
            ),
          )
          .toList(),
    );
    if (result != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(result);
    }
  }

  Future<void> _showLanguageDialog(BuildContext context, WidgetRef ref) async {
    final Locale current = ref.read(localeProvider) ?? context.locale;
    final List<Locale> supported = context.supportedLocales;
    final Locale? result = await showSelectionDialog<Locale>(
      context: context,
      title: tr('language'),
      current: current,
      items: supported
          .map(
            (Locale locale) => SelectionItem<Locale>(
              value: locale,
              title: Text(_getLocaleLabel(locale)),
            ),
          )
          .toList(),
    );
    if (result != null && context.mounted) {
      await ref.read(localeProvider.notifier).setLocale(result);
      context.setLocale(result);
    }
  }

  Future<void> _showCurrencyDialog(BuildContext context, WidgetRef ref) async {
    final String current = ref.read(defaultCurrencyProvider);
    final String? result = await showSelectionDialog<String>(
      context: context,
      title: tr('default_currency'),
      current: current,
      items: SettingsCurrencyCodes.supported
          .map(
            (String code) => SelectionItem<String>(
              value: code,
              title: Text(code),
            ),
          )
          .toList(),
    );
    if (result != null) {
      await ref.read(defaultCurrencyProvider.notifier).setCurrency(result);
    }
  }

  Future<void> _showAppThemeTypeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final AppThemeType current = ref.read(appThemeTypeProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeType? result = await showSelectionDialog<AppThemeType>(
      context: context,
      title: tr('color_scheme'),
      current: current,
      items: AppThemeType.values.map((AppThemeType type) {
        final String name = _getAppThemeTypeLabel(type);
        final Color color = AppTheme.brandSeedColor(type);
        return SelectionItem<AppThemeType>(
          value: type,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: current == type
                      ? Border.all(color: cs.primary, width: 2)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
    if (result != null) {
      await ref.read(appThemeTypeProvider.notifier).setThemeType(result);
    }
  }

  Future<void> _showDeleteAllDialog(
      BuildContext context, WidgetRef ref) async {
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
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
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
