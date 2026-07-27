import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../features/create_job/create_job_screen.dart';
import '../features/map/location_controller.dart';
import '../services/location_service.dart';
import '../features/jobs/jobs_screen.dart';
import '../features/jobs/my_jobs_screen.dart';
import '../features/map/map_screen.dart';
import '../features/settings/settings_screen.dart';
import '../l10n/app_localizations.dart';

/// The navigation scaffold.
///
/// Map first, per design principle 1 — the map is the product, so it is the
/// landing destination and posting a job is always one tap away.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Built per call rather than held as a constant: the labels change with
  /// the interface language.
  List<NavigationDestination> _destinations(AppStrings strings) => [
    NavigationDestination(
      icon: const Icon(Icons.map_outlined),
      selectedIcon: const Icon(Icons.map),
      label: strings.navMap,
    ),
    NavigationDestination(
      icon: const Icon(Icons.work_outline),
      selectedIcon: const Icon(Icons.work),
      label: strings.navJobs,
    ),
    NavigationDestination(
      icon: const Icon(Icons.bookmark_border),
      selectedIcon: const Icon(Icons.bookmark),
      label: strings.navSaved,
    ),
    NavigationDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings),
      label: strings.navSettings,
    ),
  ];

  void _openCreateJob() {
    // Open the area picker on the user where possible, so posting starts from
    // somewhere meaningful rather than an arbitrary point.
    final location =
        context.read<LocationController>().position ?? LocationService.fallback;

    Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => CreateJobScreen(initialLocation: location),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          MapScreen(),
          JobsScreen(),
          MyJobsScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: _index == 3
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateJob,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 2,
              shape: const RoundedRectangleBorder(
                borderRadius: BrandRadius.mediumAll,
              ),
              icon: const Icon(Icons.add),
              // Section 21 — say what the action does, never "Submit".
              label: Text(strings.postAJob, style: BrandType.button),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: _destinations(strings),
      ),
    );
  }
}
