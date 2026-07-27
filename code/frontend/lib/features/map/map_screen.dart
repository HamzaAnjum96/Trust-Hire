import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../app/job_controller.dart';
import '../account/account_switcher.dart';
import '../../app/profile_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/motion.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';
import '../../services/location_service.dart';
import '../../services/media_store.dart';
import '../jobs/filter_bar.dart';
import '../jobs/job_details_sheet.dart';
import '../jobs/job_filter_controller.dart';
import '../jobs/job_row.dart';
import '../profile/my_trades_screen.dart';
import '../../widgets/state_views.dart';
import 'job_map.dart';
import 'location_controller.dart';
import 'marker_cluster.dart';
import '../../l10n/app_localizations.dart';

/// The map — the primary surface of the product.
///
/// Design principle 1: jobs exist on a map, not inside long lists. Tapping a
/// pin selects it, draws its approximate work area, and raises a preview.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedJobId;
  bool _tilesUnavailable = false;

  /// Set once the camera has been framed around the jobs on first load.
  bool _framed = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _selectJob(Job job) {
    setState(() => _selectedJobId = job.id);
    _mapController.move(
      LatLng(job.location.latitude, job.location.longitude),
      _mapController.camera.zoom.clamp(14, 18),
    );
  }

  /// Zooming in on a cluster separates its pins, which is the only useful
  /// thing to do with a group of overlapping jobs.
  void _zoomToCluster(JobCluster cluster) {
    final bounds = boundsOf(cluster.jobs, paddingDegrees: 0.005);
    if (bounds == null) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(BrandSizing.spaceXl * 2),
        // Without a ceiling, a cluster of jobs at nearly the same point zooms
        // to street level and loses all context.
        maxZoom: 16,
      ),
    );
  }

  /// Opens on all of the work rather than an arbitrary point, so a job in
  /// Kashmir is not stranded off-screen with nothing hinting it exists.
  ///
  /// The padding is deliberately lopsided: the header, the filter row and any
  /// notices float *over* the map, so an evenly-fitted pin ends up behind
  /// them. These clear the tallest realistic stack at the top and the "Post a
  /// Job" button at the bottom.
  void _fitToJobs(List<Job> jobs) {
    final bounds = boundsOf(jobs);
    if (bounds == null) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(
          BrandSizing.spaceLg,
          // Header (~64) plus the filter row (~48) plus room for one notice.
          240,
          BrandSizing.spaceLg,
          // Clear of the "Post a Job" button.
          140,
        ),
        maxZoom: 14,
      ),
    );
  }

  /// How far from the opening point a job can be and still count as "here".
  ///
  /// Roughly a metropolitan area. It exists because the seed spans Karachi to
  /// Gilgit: framing *everything* opens on the whole country, where every pin
  /// is a dot and none of them is near anybody. "Show all jobs" is right there
  /// for whoever wants that view, and it should be a choice rather than the
  /// thing that happens on launch.
  static const _nearbyMetres = 60000.0;

  /// Frames the first load on the work near the opening point.
  ///
  /// The fixed opening camera used to work because the seed surrounded it.
  /// Since P1-1 a worker sees a subset, sometimes with none of it in the
  /// middle, and an empty map on first launch reads as no work available.
  ///
  /// So: fit to the jobs around wherever the map is starting — the device
  /// position when it is known, the fallback city when it is not. If there is
  /// nothing near, fit everything instead, because a distant pin the user can
  /// see beats a correct view of nothing. Runs once, and never fights a user
  /// who has since panned.
  void _frameOnFirstLoad(List<Job> jobs, {JobLocation? from}) {
    if (_framed || jobs.isEmpty) return;
    _framed = true;

    final origin = from ?? LocationService.fallback;
    final nearby = jobs
        .where((job) => origin.distanceTo(job.location) <= _nearbyMetres)
        .toList(growable: false);

    final target = nearby.isEmpty ? jobs : nearby;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitToJobs(target);
    });
  }

  void _onTilesUnavailable() {
    if (_tilesUnavailable || !mounted) return;
    setState(() => _tilesUnavailable = true);
  }

  void _clearSelection() {
    if (_selectedJobId == null) return;
    setState(() => _selectedJobId = null);
  }

  Future<void> _openDetails(Job job, JobLocation? viewerLocation) {
    return JobDetailsSheet.open(
      context,
      jobId: job.id,
      mediaStore: context.read<MediaStore>(),
      viewerLocation: viewerLocation,
    );
  }

  Future<void> _goToMyLocation(LocationController location) async {
    await location.request();
    if (!mounted) return;

    final position = location.position;
    if (position == null) return;

    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final jobs = context.watch<JobController>();
    final location = context.watch<LocationController>();
    final filters = context.watch<JobFilterController>();
    final profile = context.watch<ProfileController>();

    // The visibility rule first, then the user's filters. See
    // ProfileController.visibleTo for why a worker never sees everything.
    final reachable = profile.visibleTo(jobs.jobs, from: location.position);

    if (jobs.state == LoadState.ready) {
      _frameOnFirstLoad(reachable, from: location.position);
    }

    return Scaffold(
      body: switch (jobs.state) {
        LoadState.idle ||
        LoadState.loading => LoadingView(message: strings.loadingJobs),
        LoadState.failed => ErrorView(
          message: strings.couldNotLoadJobs,
          onRetry: jobs.load,
        ),
        LoadState.ready => _Discovery(
          jobs: filters.apply(
            reachable,
            strings: strings,
            from: location.position,
          ),
          // The count the "showing x of y" badge compares against. Reachable
          // rather than every job, so the badge measures the filters and not
          // the tag rule underneath them.
          totalJobCount: reachable.length,
          // Only ever non-zero for a worker who has not added a trade — see
          // the notice this drives.
          hiddenByTags: profile.specialities.isEmpty
              ? jobs.jobs.length - reachable.length
              : 0,
          filters: filters,
          selectedJobId: _selectedJobId,
          location: location,
          mapController: _mapController,
          tilesUnavailable: _tilesUnavailable,
          onJobTapped: _selectJob,
          onMapTapped: _clearSelection,
          onMyLocationPressed: () => _goToMyLocation(location),
          onTilesUnavailable: _onTilesUnavailable,
          onOpenJob: (job) => _openDetails(job, location.position),
          onClusterTapped: _zoomToCluster,
          onFitToJobs: _fitToJobs,
        ),
      },
    );
  }
}

/// The map, and — where there is room for it — the list beside it.
///
/// On a handset the map is the whole screen and a tapped pin raises a preview
/// card over it, because there is nowhere else for one to go. Past the
/// expanded breakpoint the same jobs get a rail of their own: the map keeps
/// showing *where*, and the rail answers *what* without covering it.
///
/// One list, not two views of one: the rail renders the same filtered jobs the
/// pins come from, and selecting in either place selects in both.
class _Discovery extends StatelessWidget {
  const _Discovery({
    required this.jobs,
    required this.totalJobCount,
    required this.hiddenByTags,
    required this.filters,
    required this.selectedJobId,
    required this.location,
    required this.mapController,
    required this.tilesUnavailable,
    required this.onJobTapped,
    required this.onMapTapped,
    required this.onMyLocationPressed,
    required this.onTilesUnavailable,
    required this.onOpenJob,
    required this.onClusterTapped,
    required this.onFitToJobs,
  });

  final List<Job> jobs;
  final int totalJobCount;
  final int hiddenByTags;
  final JobFilterController filters;
  final String? selectedJobId;
  final LocationController location;
  final MapController mapController;
  final bool tilesUnavailable;
  final ValueChanged<Job> onJobTapped;
  final VoidCallback onMapTapped;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onTilesUnavailable;
  final ValueChanged<Job> onOpenJob;
  final ValueChanged<JobCluster> onClusterTapped;
  final ValueChanged<List<Job>> onFitToJobs;

  @override
  Widget build(BuildContext context) {
    final map = _MapBody(
      jobs: jobs,
      totalJobCount: totalJobCount,
      hiddenByTags: hiddenByTags,
      filters: filters,
      selectedJobId: selectedJobId,
      location: location,
      mapController: mapController,
      tilesUnavailable: tilesUnavailable,
      // The preview card is the handset's answer to "what is this pin?". With
      // a rail beside the map that question is already answered, and a card
      // over the map would only cover it.
      showsPreviewCard: !LayoutSize.of(context).isSplit,
      onJobTapped: onJobTapped,
      onMapTapped: onMapTapped,
      onMyLocationPressed: onMyLocationPressed,
      onTilesUnavailable: onTilesUnavailable,
      onOpenJob: onOpenJob,
      onClusterTapped: onClusterTapped,
      onFitToJobs: onFitToJobs,
    );

    if (!LayoutSize.of(context).isSplit) return map;

    return Row(
      children: [
        Expanded(flex: 3, child: map),
        const VerticalDivider(width: 1, thickness: 1),
        // Fixed rather than a share of the width: a list of job rows has a
        // comfortable size, and letting it grow with the window would undo
        // the reading measure the rest of the app now keeps.
        SizedBox(
          width: 380,
          child: _ResultsRail(
            jobs: jobs,
            selectedJobId: selectedJobId,
            onSelect: onJobTapped,
            onOpen: onOpenJob,
          ),
        ),
      ],
    );
  }
}

/// The list beside the map.
class _ResultsRail extends StatelessWidget {
  const _ResultsRail({
    required this.jobs,
    required this.selectedJobId,
    required this.onSelect,
    required this.onOpen,
  });

  final List<Job> jobs;
  final String? selectedJobId;
  final ValueChanged<Job> onSelect;
  final ValueChanged<Job> onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BrandSizing.spaceMd,
              BrandSizing.spaceMd,
              BrandSizing.spaceMd,
              BrandSizing.spaceSm,
            ),
            // No count here: the map's own header carries it a hundred
            // pixels away, and the two can never disagree — the rail renders
            // exactly the jobs the pins come from.
            child: Text(strings.jobsNearby, style: theme.textTheme.titleMedium),
          ),
          const Divider(height: 1),
          Expanded(
            child: jobs.isEmpty
                ? EmptyView(
                    icon: Icons.search_off,
                    title: strings.noJobsMatch,
                    message: strings.tryWiderArea,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(BrandSizing.spaceMd),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: BrandSizing.spaceSm),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return JobRow(
                        job: job,
                        now: now,
                        isSelected: job.id == selectedJobId,
                        // One tap moves the map to it; the details are a
                        // second, deliberate tap. Opening a sheet on every
                        // click would make the list unbrowsable.
                        onTap: () => onSelect(job),
                        onOpen: () => onOpen(job),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({
    required this.jobs,
    required this.totalJobCount,
    required this.hiddenByTags,
    required this.filters,
    required this.selectedJobId,
    required this.location,
    required this.mapController,
    required this.tilesUnavailable,
    required this.onJobTapped,
    required this.onMapTapped,
    required this.onMyLocationPressed,
    required this.onTilesUnavailable,
    required this.onOpenJob,
    required this.onClusterTapped,
    required this.onFitToJobs,
    this.showsPreviewCard = true,
  });

  final List<Job> jobs;
  final int totalJobCount;

  /// False when a list beside the map is already saying what the pins are.
  final bool showsPreviewCard;

  /// How many jobs the tag rule is holding back from a worker who has not
  /// added a trade yet. Zero once they have, or for a hirer.
  final int hiddenByTags;
  final JobFilterController filters;
  final String? selectedJobId;
  final LocationController location;
  final MapController mapController;
  final bool tilesUnavailable;
  final ValueChanged<Job> onJobTapped;
  final VoidCallback onMapTapped;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onTilesUnavailable;
  final ValueChanged<Job> onOpenJob;
  final void Function(JobCluster) onClusterTapped;
  final ValueChanged<List<Job>> onFitToJobs;

  Job? get _selected {
    if (selectedJobId == null) return null;
    for (final job in jobs) {
      if (job.id == selectedJobId) return job;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final padding = MediaQuery.paddingOf(context);
    final selected = _selected;
    final locationExplanation = location.explanation(strings);

    return Stack(
      // Every child here is positioned except the preview switcher, which
      // collapses to nothing when no job is selected. Without an explicit
      // expand the Stack would size itself to that empty child and the map
      // would get no height at all.
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: JobMap(
            jobs: jobs,
            centre: location.mapCentre,
            selectedJobId: selectedJobId,
            userLocation: location.position,
            controller: mapController,
            onJobTapped: onJobTapped,
            onMapTapped: onMapTapped,
            onTilesUnavailable: onTilesUnavailable,
            onClusterTapped: onClusterTapped,
            myAccountId: context.watch<AccountController>().activeId,
          ),
        ),

        // A floating title rather than an app bar — the map should reach the
        // top of the screen.
        Positioned(
          left: BrandSizing.spaceMd,
          right: BrandSizing.spaceMd,
          top: padding.top + BrandSizing.spaceSm,
          // The map wants the whole canvas; the cards floating over it do
          // not. Left-aligned rather than centred, so the overlays sit
          // together in one column instead of drifting apart as the window
          // widens.
          child: _OverlayWidth(
            child: _MapHeader(
              jobCount: jobs.length,
              totalJobCount: totalJobCount,
            ),
          ),
        ),

        // Quick filters sit under the header, so narrowing the map never
        // means leaving it.
        Positioned(
          left: 0,
          right: 0,
          top: padding.top + 64,
          // Already a horizontal scroller, so it only needs the same ceiling
          // as the header above it to stay in the same column.
          child: _OverlayWidth(child: QuickFilterBar(controller: filters)),
        ),

        // Every notice stacks downward from below the header. One column, not
        // several absolutely-positioned children: two of these can be true at
        // once — no location *and* no tiles, or no matches *and* no trades —
        // and separate Positioned widgets at the same offset would print one
        // on top of the other.
        Positioned(
          left: BrandSizing.spaceMd,
          right: BrandSizing.spaceMd,
          top: padding.top + 116,
          child: _OverlayWidth(
            child: Column(
              spacing: BrandSizing.spaceSm,
              children: [
                if (locationExplanation != null)
                  _MapNotice(
                    icon: Icons.location_off_outlined,
                    message: locationExplanation,
                    onDismiss: location.dismissExplanation,
                  ),
                if (tilesUnavailable)
                  _MapNotice(
                    icon: Icons.cloud_off,
                    message: strings.mapImagesNotLoading,
                  ),
                if (jobs.isEmpty && totalJobCount > 0)
                  _MapNotice(
                    icon: Icons.search_off,
                    message: strings.noJobsMatchHere,
                    onDismiss: filters.clear,
                  ),

                // Not a filter and not an error: the tag rule is holding jobs
                // back, and the only thing that changes it is adding a trade.
                // Shown just for a worker who has never added one, so it stops
                // appearing as soon as it stops being news.
                if (hiddenByTags > 0)
                  _MapNotice(
                    icon: Icons.construction_outlined,
                    message: strings.noJobsForTradesHelp,
                    actionLabel: strings.addATrade,
                    onAction: () => MyTradesScreen.open(context),
                  ),
              ],
            ),
          ),
        ),

        // "Near Me" sits above the preview card so it never ends up behind it.
        AnimatedPositioned(
          duration: Motion.standard(context),
          curve: BrandMotion.curve,
          right: BrandSizing.spaceMd,
          bottom: selected != null ? 236 : 96,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.zoom_out_map,
                label: strings.showAllJobs,
                onPressed: jobs.isEmpty ? null : () => onFitToJobs(jobs),
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              _MyLocationButton(
                isBusy: location.isRequesting,
                onPressed: onMyLocationPressed,
              ),
            ],
          ),
        ),

        // Section 28 — the preview slides up rather than appearing abruptly.
        AnimatedSwitcher(
          duration: Motion.standard(context),
          switchInCurve: BrandMotion.curve,
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: (selected == null || !showsPreviewCard)
              ? const SizedBox.shrink()
              : Align(
                  key: ValueKey(selected.id),
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BrandSizing.spaceMd,
                      0,
                      BrandSizing.spaceMd,
                      // Clear the navigation bar and the post button.
                      96,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: BrandSizing.readableWidth,
                      ),
                      child: JobPreviewCard(
                        job: selected,
                        viewerLocation: location.position,
                        onOpen: () => onOpenJob(selected),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.jobCount, required this.totalJobCount});

  final int jobCount;
  final int totalJobCount;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceMd,
        vertical: BrandSizing.spaceSm + 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BrandRadius.mediumAll,
        boxShadow: BrandShadows.card,
      ),
      child: Row(
        children: [
          // The map has no app bar to hang the account switcher off, and the
          // landing screen is the one place a demonstration must not leave
          // "who am I?" unanswered. It takes the header's leading slot: the
          // heading beside it already says these are jobs near a place, so
          // the pin icon was saying it twice.
          Tooltip(
            message: strings.switchAccount,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => AccountSheet.open(context),
              // The avatar is drawn at 28px, but section 29 asks for a 48px
              // target and a circle is harder to hit than a rectangle. The
              // box is invisible; only the reach changes.
              child: SizedBox(
                width: BrandSizing.touchTargetPreferred,
                height: BrandSizing.touchTargetPreferred,
                child: Center(
                  child: AccountAvatar(
                    account: context.watch<AccountController>().active,
                    radius: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(strings.nearbyWork, style: theme.textTheme.titleLarge),
          ),
          Text(
            // Say what is being hidden, so a short list never looks like a
            // bug.
            jobCount == totalJobCount
                ? strings.jobCount(jobCount)
                : strings.jobCountFiltered(jobCount, totalJobCount),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Caps a floating map overlay and pins it to the leading edge.
///
/// A notice stretched across a 1440px browser is a line of text with a metre
/// of white beside it, and the header's count ends up half a screen from its
/// title. Leading-aligned rather than centred so the header, the filters and
/// the notices read as one stack.
class _OverlayWidth extends StatelessWidget {
  const _OverlayWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BrandSizing.readableWidth),
        child: child,
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({
    required this.icon,
    required this.message,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onDismiss;

  /// An optional way out of whatever the notice describes. Dismissing is not
  /// always the right offer: nothing changes for a worker who closes the
  /// trades notice without adding one.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceSm + 4,
        BrandSizing.spaceSm,
        BrandSizing.spaceSm + 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BrandRadius.mediumAll,
        border: Border.all(
          color: BrandColours.informationBlue.withValues(alpha: 0.35),
        ),
        boxShadow: BrandShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: BrandColours.informationBlue),
              const SizedBox(width: BrandSizing.spaceSm + 4),
              Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: strings.dismiss,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: BrandSizing.spaceSm),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A square map control, matching the "Near Me" button.
class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BrandRadius.mediumAll,
      elevation: 2,
      shadowColor: BrandColours.ink.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BrandRadius.mediumAll,
        child: SizedBox(
          width: BrandSizing.touchTargetPreferred,
          height: BrandSizing.touchTargetPreferred,
          child: Icon(
            icon,
            color: onPressed == null
                ? theme.colorScheme.outline
                : theme.colorScheme.primary,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}

class _MyLocationButton extends StatelessWidget {
  const _MyLocationButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BrandRadius.mediumAll,
      elevation: 2,
      shadowColor: BrandColours.ink.withValues(alpha: 0.2),
      child: InkWell(
        onTap: isBusy ? null : onPressed,
        borderRadius: BrandRadius.mediumAll,
        child: SizedBox(
          width: BrandSizing.touchTargetPreferred,
          height: BrandSizing.touchTargetPreferred,
          child: isBusy
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(
                  Icons.my_location,
                  color: theme.colorScheme.primary,
                  semanticLabel: strings.nearMeLabel,
                ),
        ),
      ),
    );
  }
}

/// Compact preview raised when a pin is tapped.
///
/// Sprint 2 replaces the "View Job" action with the full bottom sheet; this
/// already gives the user enough to decide whether to open it.
class JobPreviewCard extends StatelessWidget {
  const JobPreviewCard({
    super.key,
    required this.job,
    this.viewerLocation,
    this.onOpen,
  });

  final Job job;
  final JobLocation? viewerLocation;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final distance = Format.distanceToJob(strings, viewerLocation, job);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BrandRadius.largeAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: BrandShadows.card,
      ),
      padding: const EdgeInsets.all(BrandSizing.spaceMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.displayTitle(strings),
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (job.isPostedBy(context.watch<AccountController>().activeId))
                ...[
                  const SizedBox(width: BrandSizing.spaceSm),
                  const _LocalBadge(),
                ],
            ],
          ),
          if (job.supportingDescription != null) ...[
            const SizedBox(height: BrandSizing.spaceXs),
            Text(
              job.supportingDescription!,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: BrandSizing.spaceSm + 4),
          Wrap(
            spacing: BrandSizing.spaceMd,
            runSpacing: BrandSizing.spaceXs,
            children: [
              _MetaChip(
                icon: Icons.schedule,
                label: Format.scheduled(strings, job.scheduledTime, now),
              ),
              if (distance != null)
                _MetaChip(icon: Icons.near_me_outlined, label: distance),
              _MetaChip(
                icon: Icons.radio_button_unchecked,
                label: Format.radius(strings, job.radiusMetres),
              ),
              if (job.hasVoiceNote)
                _MetaChip(icon: Icons.mic, label: strings.voiceNote),
              if (job.hasPhotos)
                _MetaChip(
                  icon: Icons.photo_library_outlined,
                  label: strings.photoCount(job.photoPaths.length),
                ),
            ],
          ),
          if (onOpen != null) ...[
            const SizedBox(height: BrandSizing.spaceMd),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onOpen,
                child: const Text('View Job'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceSm,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: BrandColours.copper,
        borderRadius: BrandRadius.smallAll,
      ),
      child: Text(
        strings.onThisDevice,
        style: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w600,
          color: BrandColours.white,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: BrandSizing.spaceXs + 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
