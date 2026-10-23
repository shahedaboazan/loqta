import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/brand_logo.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/settings/domain/entities/app_preferences.dart';
import 'package:loqta/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:loqta/features/settings/presentation/pages/security_privacy_page.dart';

/// Settings.
///
/// Reached from Profile. Provides the working, persisted Light/Dark and
/// English/Arabic selections, plus the entry points into Security & Privacy and
/// the About block.
///
/// Both toggles dispatch to [SettingsBloc] rather than calling `setState`: that
/// bloc sits above `MaterialApp`, so a change here repaints the entire app —
/// including the LTR/RTL flip — without this page holding a duplicate copy of
/// the preference.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final strings = context.l10n;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LoqtaAppBar(
              title: strings.settings,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  LoqtaSpacing.gutter,
                  8,
                  LoqtaSpacing.gutter,
                  24,
                ),
                children: [
                  _GroupLabel(strings.language),
                  const SizedBox(height: 10),
                  _LanguageSelector(),
                  const SizedBox(height: 22),
                  _GroupLabel(strings.theme),
                  const SizedBox(height: 10),
                  _ThemeSelector(),
                  const SizedBox(height: 22),
                  _GroupLabel(strings.account),
                  const SizedBox(height: 10),
                  _SettingsRow(
                    icon: Icons.shield_outlined,
                    label: strings.securityPrivacy,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SecurityPrivacyPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _GroupLabel(strings.aboutLoqta),
                  const SizedBox(height: 10),
                  _AboutCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontFamily: LoqtaText.family,
      ),
    );
  }
}

/// A two-option segmented control.
///
/// The currently selected option is derived from the bloc, so it is correct even
/// after an app restart — the value on screen always reflects what was
/// persisted, not what this screen last set.
class _SegmentedOption<T> extends StatelessWidget {
  const _SegmentedOption({
    required this.value,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final T value;
  final T selected;
  final String label;
  final IconData? icon;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final primary = Theme.of(context).colorScheme.primary;
    final isSelected = value == selected;

    return Expanded(
      child: Material(
        color: isSelected ? primary : palette.surface,
        borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
        child: InkWell(
          onTap: () => onSelected(value),
          borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
              border: Border.all(color: isSelected ? primary : palette.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 17,
                    color: isSelected ? Colors.white : palette.textSecondary,
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: LoqtaText.fieldLabel.copyWith(
                    color: isSelected ? Colors.white : palette.heading,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        // Until the persisted value loads, fall back to the locale Material
        // actually resolved, so the control never briefly claims the wrong
        // language is active.
        final active =
            state.preferences.localeCode ?? context.appLocale.languageCode;
        return Row(
          children: [
            _SegmentedOption<String>(
              value: 'en',
              selected: active,
              label: strings.english,
              icon: Icons.language,
              onSelected: (_) => context.read<SettingsBloc>().add(
                const SettingsLocaleChanged('en'),
              ),
            ),
            const SizedBox(width: 10),
            _SegmentedOption<String>(
              value: 'ar',
              selected: active,
              label: strings.arabic,
              icon: Icons.language,
              onSelected: (_) => context.read<SettingsBloc>().add(
                const SettingsLocaleChanged('ar'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Row(
          children: [
            _SegmentedOption<AppThemeMode>(
              value: AppThemeMode.light,
              selected: state.preferences.themeMode,
              label: strings.lightMode,
              icon: Icons.light_mode_outlined,
              onSelected: (mode) => context.read<SettingsBloc>().add(
                SettingsThemeModeChanged(mode),
              ),
            ),
            const SizedBox(width: 10),
            _SegmentedOption<AppThemeMode>(
              value: AppThemeMode.dark,
              selected: state.preferences.themeMode,
              label: strings.darkMode,
              icon: Icons.dark_mode_outlined,
              onSelected: (mode) => context.read<SettingsBloc>().add(
                SettingsThemeModeChanged(mode),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.heading),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: LoqtaText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.heading,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final strings = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          const BrandLogo(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.appName,
                  style: LoqtaText.fieldLabel.copyWith(color: palette.heading),
                ),
                const SizedBox(height: 2),
                Text(
                  '${strings.version} 1.0.0',
                  style: LoqtaText.caption.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
