import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/layout.dart';
import '../core/tokens.dart';
import '../features/create_job/create_job_screen.dart';
import '../features/map/location_controller.dart';
import '../services/location_service.dart';
import '../features/jobs/jobs_screen.dart';
import '../features/jobs/my_jobs_screen.dart';
import '../features/directory/directory_screen.dart';
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

  /// The destinations, once.
  ///
  /// The bottom bar and the side rail take different widget types, so they
  /// used to hold two hand-written lists — which drifted the moment a fifth
  /// destination arrived: the rail kept showing four, and tapping "Profile"
  /// on a desktop opened Activity. One list, mapped twice.
  ///
  /// Built per call rather than held as a constant, because the labels change
  /// with the interface language.
  List<_Destination> _destinations(AppStrings strings) => [
    _Destination(Icons.map_outlined, Icons.map, strings.navMap),
    _Destination(Icons.work_outline, Icons.work, strings.navJobs),
    // Mode B, and a destination rather than a filter on the map. Section 9
    // calls it "a second, parallel discovery mode": the map answers where
    // there is work, the directory answers who can do a thing and what they
    // charge. Folding one into the other would make both worse.
    _Destination(Icons.badge_outlined, Icons.badge, strings.navDirectory),
    // "Activity", not "Saved": the screen behind it has always held saved,
    // posted and offered jobs, and naming it after one of its three tabs sent
    // anyone looking for the others to the wrong place.
    _Destination(
      Icons.bookmark_border,
      Icons.bookmark,
      strings.navActivity,
    ),
    // "Profile", not "Settings": role and trades decide what the rest of the
    // app shows, which is not a setting — and a marketplace with no profile
    // destination has nowhere to put trust signals later.
    _Destination(Icons.person_outline, Icons.person, strings.navProfile),
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

  static const _profileIndex = 4;

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
        DirectoryScreen(),
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
              destinations: _destinations(strings),
              onSelected: (value) => setState(() => _index = value),
              // Extended labels need the room; a tablet does not have it.
              extended: layout == LayoutSize.expanded,
              // **Labelled wherever there is room for a label.** A bare "+"
              // above a navigation rail reads as part of the furniture; the
              // one thing this app is for should say what it does. On a
              // tablet-width rail there is no room for the word, so the icon
              // keeps its tooltip and the destinations carry the meaning.
              action: _showsPostAction
                  ? (layout == LayoutSize.expanded
                        ? FloatingActionButton.extended(
                            onPressed: _openCreateJob,
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 2,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BrandRadius.mediumAll,
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(
                              strings.postAJob,
                              style: BrandType.button,
                            ),
                          )
                        : Column(
                            children: [
                              FloatingActionButton(
                                onPressed: _openCreateJob,
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                elevation: 2,
                                tooltip: strings.postAJob,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BrandRadius.mediumAll,
                                ),
                                child: const Icon(Icons.add),
                              ),
                              const SizedBox(height: BrandSizing.spaceXs),
                              // Every destination below this carries a label.
                              // A bare "+" at the top of a labelled column
                              // reads as furniture rather than as the app's
                              // one primary action.
                              Text(
                                strings.postAJob,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ))
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
        destinations: [
          for (final destination in _destinations(strings))
            destination.forBar,
        ],
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
    required this.destinations,
    this.action,
  });

  final List<_Destination> destinations;
  final int index;
  final ValueChanged<int> onSelected;
  final bool extended;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
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
                for (final destination in destinations) destination.forRail,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One place the app can be, in whichever navigation control is on screen.
class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  NavigationDestination get forBar => NavigationDestination(
    icon: Icon(icon),
    selectedIcon: Icon(selectedIcon),
    label: label,
  );

  NavigationRailDestination get forRail => NavigationRailDestination(
    icon: Icon(icon),
    selectedIcon: Icon(selectedIcon),
    label: Text(label),
  );
}
