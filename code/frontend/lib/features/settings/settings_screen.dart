import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/settings_controller.dart';
import '../../core/tokens.dart';
import '../../widgets/state_views.dart';

/// Settings — theme, and the local-data controls the POC needs.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        children: [
          const NoticePanel(
            message:
                'This POC stores jobs only on this device. '
                'Nothing is uploaded and no account is needed.',
          ),
          const SizedBox(height: BrandSizing.spaceLg),

          Text('Appearance', style: theme.textTheme.titleLarge),
          const SizedBox(height: BrandSizing.spaceSm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                settings.setThemeMode(selection.first),
          ),

          const SizedBox(height: BrandSizing.spaceXl),
          Text('Local data', style: theme.textTheme.titleLarge),
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
            label: const Text('Restore Seed Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final controller = context.read<JobController>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BrandRadius.largeAll),
        title: const Text('Restore seed data?'),
        content: const Text(
          'Jobs you created on this device will be removed. This cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep My Jobs'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BrandColours.errorRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restore Seed Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.resetToSeed();
    messenger.showSnackBar(
      const SnackBar(content: Text('Seed data restored.')),
    );
  }
}
