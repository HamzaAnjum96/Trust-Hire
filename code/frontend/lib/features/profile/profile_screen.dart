import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/profile_controller.dart';
import '../../app/settings_controller.dart';
import '../../core/app_version.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../models/worker_profile.dart';
import '../../widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import '../profile/my_trades_screen.dart';

/// Who you are here, and how the app behaves for you.
///
/// Role and trades are not settings — they decide which jobs the rest of the
/// app shows you at all — so they lead, above the appearance and language
/// controls. Giving them a destination of their own also gives P1-5 somewhere
/// to put a rating, a completed-jobs count and a fare average, rather than
/// bolting a marketplace identity onto a preferences screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.navProfile)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
          children: [
            NoticePanel(message: strings.settingsStorageNotice),
            SizedBox(height: BrandSizing.spaceLg),

            // First, because it changes what the rest of the app shows: a
            // worker gets a feed filtered to their trades, a hirer gets the
            // jobs they posted.
            Text(strings.whatBringsYouHere, style: theme.textTheme.titleLarge),
            const SizedBox(height: BrandSizing.spaceSm),
            const _RolePicker(),

            const SizedBox(height: BrandSizing.spaceXl),
            Text(strings.navSettings, style: theme.textTheme.titleLarge),
            const SizedBox(height: BrandSizing.spaceSm),
            Text(strings.appearance, style: theme.textTheme.titleMedium),
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

            const SizedBox(height: BrandSizing.spaceLg),
            Text(strings.language, style: theme.textTheme.titleMedium),
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

            const SizedBox(height: BrandSizing.spaceLg),
            Text(strings.localData, style: theme.textTheme.titleMedium),
            const SizedBox(height: BrandSizing.spaceSm),
            Text(
              strings.restoreSeedExplanation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: BrandSizing.spaceMd),
            OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await settings.resetIntro();
                messenger.showSnackBar(
                  SnackBar(content: Text(strings.introReset)),
                );
              },
              icon: const Icon(Icons.slideshow_outlined),
              label: Text(strings.showIntroAgain),
            ),
            const SizedBox(height: BrandSizing.spaceSm),
            OutlinedButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.restart_alt),
              // Section 21 — explicit label, never "Confirm".
              label: Text(strings.restoreSeedData),
            ),

            const _VersionLine(),
          ],
        ),
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
        content: Text(strings.restoreSeedWarning),
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

/// The build, at the foot of settings — where people look for it.
class _VersionLine extends StatelessWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: BrandSizing.spaceXl),
      child: Text(
        AppVersion.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Worker or hirer, and — for a worker — the way through to their trades.
///
/// Switching role never touches the tag list. Someone who hires a painter
/// today and looks for work tomorrow should not have to pick their trades
/// again, and quietly clearing them would empty their feed with no explanation.
class _RolePicker extends StatelessWidget {
  const _RolePicker();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final profile = context.watch<ProfileController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<UserRole>(
          segments: [
            ButtonSegment(
              value: UserRole.worker,
              label: Text(strings.roleWorker),
              icon: const Icon(Icons.handyman_outlined),
            ),
            ButtonSegment(
              value: UserRole.hirer,
              label: Text(strings.roleHirer),
              icon: const Icon(Icons.post_add_outlined),
            ),
          ],
          selected: {profile.role},
          onSelectionChanged: (selection) => profile.setRole(selection.first),
        ),
        const SizedBox(height: BrandSizing.spaceSm),
        Text(
          profile.isWorker ? strings.roleWorkerHelp : strings.roleHirerHelp,
          style: theme.textTheme.labelSmall,
        ),
        if (profile.isWorker) ...[
          const SizedBox(height: BrandSizing.spaceSm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.construction_outlined),
            title: Text(strings.myTrades),
            subtitle: Text(strings.tradeCount(profile.specialities.length)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => MyTradesScreen.open(context),
          ),
        ],
      ],
    );
  }
}
