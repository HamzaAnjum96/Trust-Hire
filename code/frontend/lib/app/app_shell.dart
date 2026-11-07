import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/layout.dart';
import '../core/theme.dart';
import '../core/tokens.dart';
import '../features/create_job/create_job_screen.dart';
import '../features/map/location_controller.dart';
import '../services/location_service.dart';
import '../features/jobs/my_jobs_screen.dart';
import '../features/directory/directory_screen.dart';
import '../features/map/map_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/notifications/updates_tab.dart';
import '../features/wallet/stripe_return.dart';
import '../l10n/app_localizations.dart';
import '../services/browser_location.dart';
import 'job_controller.dart';
import 'message_controller.dart';
import 'notification_controller.dart';
import 'wallet_controller.dart';

/// The navigation scaffold.
///
/// **Four destinations and one action.** Since 0.23:
///
/// - *Jobs* is the map and the list of the same results, one destination with
///   a view switch inside it. They used to be two destinations, Map and Jobs,
///   sharing one filter state, and on a desktop the map already carried the
///   list beside it — so the second destination was the first one's sidebar.
/// - *Post a Job* is an action, so it is drawn as a button and never becomes
///   the selected destination. On a handset it sits in the middle of the bar,
///   where it is one tap away on every screen and covers nothing; it used to
///   float over the last rows of every list.
///
/// See `documents/design/2026-11-04-redesign.md` for the rest of the reasoning.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.location});

  /// The address the app was opened at. Null means the real one; tests pass
  /// a return from Stripe here.
  final Uri? location;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // After the first frame, so there is a messenger to say what happened.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _completeStripeReturn(),
    );
  }

  /// The app has just been opened by Stripe sending a buyer back from a
  /// Payment Link. Credit it if this browser started it — see [StripeReturn]
  /// for what that does and does not establish — and say so.
  ///
  /// Here rather than in `bootstrap()`: crediting goes through
  /// [WalletController], so the ledger in memory and the one in storage are
  /// the same ledger. Written behind the controller's back, the next thing the
  /// wallet saved would put the old balance back.
  Future<void> _completeStripeReturn() async {
    final location = widget.location ?? Uri.base;
    final returned = StripeReturn.from(location);
    if (returned == null || !mounted) return;

    // First, so that whatever happens next, a reload does not bring it back.
    replaceBrowserLocation(StripeReturn.cleaned(location));

    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await context.read<WalletController>().completeStripeReturn(
      returned,
    );
    if (!mounted) return;

    final message = switch (outcome) {
      StripeReturnOutcome.credited => strings.topUpDone(
        Format.fare(strings, returned.tokens),
      ),
      StripeReturnOutcome.notMatched => strings.topUpNotMatched,
      // Nothing to say about a return nobody here started, or one already
      // counted — the first is not this person's business, the second is not
      // news.
      StripeReturnOutcome.notStartedHere ||
      StripeReturnOutcome.alreadyCredited => null,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// The destinations, once.
  ///
  /// The bottom bar and the side rail take different widget types, so they
  /// used to hold two hand-written lists — which drifted the moment a fifth
  /// destination arrived: the rail kept showing four, and tapping "Profile"
  /// on a desktop opened Activity. One list, mapped twice.
  ///
  /// Built per call rather than held as a constant, because the labels change
  /// with the interface language.
  List<_Destination> _destinations(AppStrings strings, int waiting) => [
    // The map and the list of the same jobs. Named for what is in it rather
    // than for one of its two views.
    _Destination(Icons.work_outline, Icons.work, strings.navJobs),
    // Mode B, and a destination rather than a filter on the map. Section 9
    // calls it "a second, parallel discovery mode": the map answers where
    // there is work, the directory answers who can do a thing and what they
    // charge. Folding one into the other would make both worse.
    _Destination(Icons.badge_outlined, Icons.badge, strings.navDirectory),
    _Destination(
      Icons.bookmark_border,
      Icons.bookmark,
      strings.navActivity,
      // **The reason to look.** Everything else in this bar is somewhere you
      // decide to go; this is the one that can have news in it. It counts
      // conversations waiting for a reply as well as unseen updates: until
      // 0.23 a new message raised no badge anywhere.
      badge: waiting,
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

  /// Where the posting button sits in the bottom bar: the middle, so it is
  /// under either thumb and reads as separate from the places either side.
  static const _postSlot = 2;

  int _barIndexOf(int page) => page < _postSlot ? page : page + 1;
  int _pageOf(int barIndex) => barIndex < _postSlot ? barIndex : barIndex - 1;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final layout = LayoutSize.of(context);

    // Derived from the same rules the Updates tab uses, so the number on the
    // badge and the number of highlighted rows behind it cannot disagree.
    final unseen = context.watch<NotificationController>().unseen(
      buildFeed(context),
    );
    final unanswered = context.watch<MessageController>().threadsWaiting(
      context.watch<JobController>().jobs,
    );
    final destinations = _destinations(strings, unseen + unanswered);

    final body = IndexedStack(
      index: _index,
      children: const [
        MapScreen(),
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
      final extended = layout == LayoutSize.expanded;
      return Scaffold(
        body: Row(
          children: [
            _NavigationRail(
              index: _index,
              destinations: destinations,
              onSelected: (value) => setState(() => _index = value),
              // Extended labels need the room; a tablet does not have it.
              extended: extended,
              action: PostJobButton(
                onPressed: _openCreateJob,
                shape: extended ? PostJobShape.wide : PostJobShape.stacked,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: body,
      bottomNavigationBar: DecoratedBox(
        // A hairline rather than a shadow: the bar is the floor of the
        // screen, not something floating over it.
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _barIndexOf(_index),
          onDestinationSelected: (value) {
            // The posting slot handles its own tap; it is never a place.
            if (value == _postSlot) return;
            setState(() => _index = _pageOf(value));
          },
          destinations: [
            for (final (i, destination) in destinations.indexed) ...[
              if (i == _postSlot)
                PostJobButton(
                  onPressed: _openCreateJob,
                  shape: PostJobShape.barSlot,
                ),
              destination.forBar,
            ],
          ],
        ),
      ),
    );
  }
}

/// How much room the posting action has.
enum PostJobShape {
  /// Icon and label side by side. An extended rail.
  wide,

  /// Icon above a label, matching the destinations under it. A rail too
  /// narrow for a word beside an icon.
  stacked,

  /// One slot of the bottom bar, the same size as the destinations beside it
  /// but filled, so it reads as a button among places.
  barSlot,
}

/// The app's one primary action, in one place.
///
/// **It had grown three copies** — the bottom bar, the extended rail and the
/// narrow rail — each repeating the same five lines of brand styling, and the
/// third was added the day after a report that the button was hard to find.
/// Three copies of a thing that must look identical is how one of them ends up
/// not.
///
/// Always labelled. An unlabelled "+" above labelled destinations reads as
/// furniture rather than as the thing the app is for, which is what the report
/// was describing.
class PostJobButton extends StatelessWidget {
  const PostJobButton({
    super.key,
    required this.onPressed,
    required this.shape,
  });

  final VoidCallback onPressed;
  final PostJobShape shape;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    Widget fab({Widget? child, Widget? icon, Widget? label}) => icon == null
        ? FloatingActionButton(
            heroTag: null,
            onPressed: onPressed,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 1,
            tooltip: strings.postAJob,
            shape: const RoundedRectangleBorder(
              borderRadius: BrandRadius.mediumAll,
            ),
            child: child,
          )
        : FloatingActionButton.extended(
            heroTag: null,
            onPressed: onPressed,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 1,
            shape: const RoundedRectangleBorder(
              borderRadius: BrandRadius.mediumAll,
            ),
            icon: icon,
            label: label!,
          );

    return switch (shape) {
      // Section 21 — say what the action does, never "Submit".
      PostJobShape.wide => fab(
        icon: const Icon(Icons.add),
        label: Text(strings.postAJob, style: BrandType.button),
      ),
      PostJobShape.stacked => Column(
        children: [
          fab(child: const Icon(Icons.add)),
          const SizedBox(height: BrandSizing.spaceXs),
          Text(
            strings.postAJob,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
      PostJobShape.barSlot => _BarSlot(onPressed: onPressed),
    };
  }
}

/// The posting button as one slot of the bottom bar.
///
/// The same footprint as a destination — a 64×32 pill over a label — so the
/// bar keeps one rhythm, but the pill is always filled burgundy with a white
/// glyph. A selected destination is a sand pill with a burgundy glyph, so the
/// two can never be mistaken for each other.
class _BarSlot extends StatelessWidget {
  const _BarSlot({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    // Already inside an Expanded: NavigationBar gives every slot one.
    return Semantics(
      button: true,
      label: strings.postAJob,
      // The tap is stated here because the InkWell's own is excluded with
      // the rest of what is under it — and the bar insists every slot can be
      // tapped by somebody who cannot see it.
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: strings.postAJob,
        child: InkWell(
          onTap: onPressed,
          customBorder: const RoundedRectangleBorder(
            borderRadius: BrandRadius.mediumAll,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BrandRadius.mediumAll,
                ),
                child: Icon(
                  Icons.add,
                  size: 24,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: BrandSizing.spaceXs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  strings.postAJob,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrandType.caption.copyWith(
                    color: theme.accentText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The side navigation used from the medium breakpoint upward.
///
/// Its own widget so the shell's build stays readable, and so the rail's
/// scroll behaviour is contained: at 600px height with the destinations and
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
              leading: Padding(
                padding: const EdgeInsets.only(
                  top: BrandSizing.spaceMd,
                  bottom: BrandSizing.spaceLg,
                ),
                child: Column(
                  crossAxisAlignment: extended
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    _RailMark(extended: extended),
                    if (action != null) ...[
                      const SizedBox(height: BrandSizing.spaceLg),
                      action!,
                    ],
                  ],
                ),
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

/// The product's name at the head of the rail.
///
/// A desktop window with navigation and no name on it reads as a tool
/// somebody else built. The mark is the app icon's pin, drawn rather than
/// loaded, so it follows the theme.
class _RailMark extends StatelessWidget {
  const _RailMark({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final pin = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BrandRadius.smallAll,
      ),
      child: Icon(
        Icons.location_on,
        size: 22,
        color: theme.colorScheme.onPrimary,
      ),
    );

    if (!extended) {
      return Semantics(label: strings.appTitle, child: pin);
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: BrandSizing.spaceXs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pin,
          const SizedBox(width: BrandSizing.spaceSm + 2),
          Text(
            strings.appTitle,
            style: BrandType.sectionHeading.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One place the app can be, in whichever navigation control is on screen.
class _Destination {
  const _Destination(
    this.icon,
    this.selectedIcon,
    this.label, {
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// How many unseen things are waiting behind this destination. Zero draws
  /// nothing — an empty badge is a decoration that teaches people to ignore
  /// badges.
  final int badge;

  /// Both navigation controls take a plain icon widget, so the badge is
  /// applied once here rather than at each of the two call sites.
  Widget _wrap(IconData glyph) =>
      badge == 0 ? Icon(glyph) : Badge.count(count: badge, child: Icon(glyph));

  NavigationDestination get forBar => NavigationDestination(
    icon: _wrap(icon),
    selectedIcon: _wrap(selectedIcon),
    label: label,
  );

  NavigationRailDestination get forRail => NavigationRailDestination(
    icon: _wrap(icon),
    selectedIcon: _wrap(selectedIcon),
    label: Text(label),
  );
}
