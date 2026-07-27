import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/settings_controller.dart';
import '../../core/tokens.dart';
import '../../widgets/state_views.dart';
import '../../l10n/app_localizations.dart';

/// Settings — theme, and the local-data controls the POC needs.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        children: [
          const NoticePanel(
            message:
                'This POC stores jobs only on this device. '
                'Nothing is uploaded and no account is needed.',
          ),
          SizedBox(height: BrandSizing.spaceLg),

          Text(strings.appearance, style: theme.textTheme.titleLarge),
          SizedBox(height: BrandSizing.spaceSm),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(strings.themeSystem),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(strings.themeLight),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(strings.themeDark),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                settings.setThemeMode(selection.first),
          ),

          const SizedBox(height: BrandSizing.spaceXl),
          Text(strings.language, style: theme.textTheme.titleLarge),
          const SizedBox(height: BrandSizing.spaceSm),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: '',
                label: Text(strings.themeSystem),
                icon: const Icon(Icons.translate),
              ),
              for (final locale in SettingsController.supportedLocales)
                ButtonSegment(
                  value: locale.languageCode,
                  // Each language names itself, so someone who cannot read
                  // the current one can still find their own.
                  label: Text(
                    AppStrings.of(context).localeName == locale.languageCode
                        ? strings.languageName
                        : _languageName(locale.languageCode),
                  ),
                ),
            ],
            selected: {settings.locale?.languageCode ?? ''},
            onSelectionChanged: (selection) => settings.setLocale(
              selection.first.isEmpty ? null : Locale(selection.first),
            ),
          ),

          const SizedBox(height: BrandSizing.spaceXl),
          Text(strings.localData, style: theme.textTheme.titleLarge),
          const SizedBox(height: BrandSizing.spaceSm),
          Text(
            'Restoring the seed data removes every job you created on this '
            'device and brings back the original examples.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: BrandSizing.spaceMd),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.restart_alt),
            // Section 21 — explicit label, never "Confirm".
            label: Text(strings.restoreSeedData),
          ),
        ],
      ),
    );
  }

  /// A language's own name, so it is legible to whoever speaks it regardless
  /// of the interface language currently in force.
  static String _languageName(String code) => switch (code) {
    'ur' => 'اردو',
    _ => 'English',
  };

  Future<void> _confirmReset(BuildContext context) async {
    final strings = AppStrings.of(context);
    final controller = context.read<JobController>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BrandRadius.largeAll),
        title: Text(strings.restoreSeedTitle),
        content: const Text(
          'Jobs you created on this device will be removed. This cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.keepMyJobs),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BrandColours.errorRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.restoreSeedData),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.resetToSeed();
    messenger.showSnackBar(SnackBar(content: Text(strings.seedRestored)));
  }
}
