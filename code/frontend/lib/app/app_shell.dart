import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/layout.dart';
import '../core/tokens.dart';
import '../features/create_job/create_job_screen.dart';
import '../features/map/location_controller.dart';
import '../services/location_service.dart';
import '../features/jobs/jobs_screen.dart';
import '../features/jobs/my_jobs_screen.dart';
import '../features/map/map_screen.dart';
import '../features/profile/profile_screen.dart';
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
    // "Activity", not "Saved": the screen behind it has always held both
    // saved and posted jobs, and naming it after one of its two tabs sent
    // anyone looking for their own postings to the wrong place.
    NavigationDestination(
      icon: const Icon(Icons.bookmark_border),
      selectedIcon: const Icon(Icons.bookmark),
      label: strings.navActivity,
    ),
    // "Profile", not "Settings": role and trades decide what the rest of the
    // app shows, which is not a setting — and a marketplace with no profile
    // destination has nowhere to put trust signals later.
    NavigationDestination(
      icon: const Icon(Icons.person_outline),
      selectedIcon: const Icon(Icons.person),
      label: strings.navProfile,
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

  /// Posting is the app's one primary action, so it is present on every
  /// destination except the one that is about the user rather than the work.
  bool get _showsPostAction => _index != _profileIndex;

  static const _profileIndex = 3;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final layout = LayoutSize.of(context);

    final body = IndexedStack(
      index: _index,
      children: const [
        MapScreen(),
        JobsScreen(),
        MyJobsScreen(),
        ProfileScreen(),
      ],
    );

    // A bottom bar on a desktop browser puts the app's main controls as far
    // from the pointer as the window allows. Past the medium breakpoint the
    // destinations move to a rail down the side, which is also where a mouse
    // already is on the way back from the address bar.
    if (layout.usesRail) {
      return Scaffold(
        body: Row(
          children: [
            _NavigationRail(
              index: _index,
              onSelected: (value) => setState(() => _index = value),
              // Extended labels need the room; a tablet does not have it.
              extended: layout == LayoutSize.expanded,
              action: _showsPostAction
                  ? FloatingActionButton(
                      onPressed: _openCreateJob,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 2,
                      tooltip: strings.postAJob,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BrandRadius.mediumAll,
                      ),
                      child: const Icon(Icons.add),
                    )
                  : null,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: _showsPostAction
          ? FloatingActionButton.extended(
              onPressed: _openCreateJob,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 2,
              shape: const RoundedRectangleBorder(
                borderRadius: BrandRadius.mediumAll,
              ),
              icon: const Icon(Icons.add),
              // Section 21 — say what the action does, never "Submit".
              label: Text(strings.postAJob, style: BrandType.button),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: _destinations(strings),
      ),
    );
  }
}

/// The side navigation used from the medium breakpoint upward.
///
/// Its own widget so the shell's build stays readable, and so the rail's
/// scroll behaviour is contained: at 600px height with four destinations and
/// a button, the rail can overflow, and a navigation control that clips is
/// worse than one that scrolls.
class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.index,
    required this.onSelected,
    required this.extended,
    this.action,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final bool extended;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: index,
              onDestinationSelected: onSelected,
              extended: extended,
              labelType: extended ? null : NavigationRailLabelType.all,
              leading: action == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: BrandSizing.spaceMd,
                      ),
                      child: action,
                    ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map),
                  label: Text(strings.navMap),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.work_outline),
                  selectedIcon: const Icon(Icons.work),
                  label: Text(strings.navJobs),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.bookmark_border),
                  selectedIcon: const Icon(Icons.bookmark),
                  label: Text(strings.navActivity),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: Text(strings.navProfile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
