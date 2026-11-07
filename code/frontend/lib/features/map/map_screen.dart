import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../app/job_controller.dart';
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
import '../jobs/job_results.dart';
import '../jobs/job_row.dart';
import '../profile/my_trades_screen.dart';
import '../../widgets/meta_chip.dart';
import '../../widgets/state_views.dart';
import '../../widgets/fare_tag.dart';
import '../../widgets/mine_badge.dart';
import 'job_map.dart';
import 'map_overlays.dart';
import 'location_controller.dart';
import 'marker_cluster.dart';
import '../../l10n/app_localizations.dart';

/// The Jobs destination: the map, and the same results as a list.
///
/// Design principle 1: jobs exist on a map, not inside long lists. Tapping a
/// pin selects it, draws its approximate work area, and raises a preview.
///
/// **Since 0.23 the list lives here too.** It was a destination of its own,
/// and the two were the same jobs under one shared filter state, a tab apart.
/// Now a view switch at the bottom of the screen turns the map into the list
/// and back, under one search bar; on a desktop both are on screen at once
/// and the switch is not drawn.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedJobId;
  bool _tilesUnavailable = false;

  /// Whether the list is showing instead of the map, where only one fits.
  /// The map is the default: it is the product.
  bool _showingList = false;

  void _toggleView() => setState(() {
    _showingList = !_showingList;
    // A pin selected on the map means nothing in the list.
    _selectedJobId = null;
  });

  /// The opening camera, worked out once the jobs are known.
  ///
  /// Held rather than applied, and handed to [JobMap] as the map's *initial*
  /// fit — see [_openingFit] for why that matters.
  CameraFit? _openingFit;

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
  static CameraFit? _fitAround(List<Job> jobs) {
    final bounds = boundsOf(jobs);
    if (bounds == null) return null;

    return CameraFit.bounds(
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
    );
  }

  /// The same fit, applied now. For the "show all jobs" button, which the
  /// user presses long after the map has a size.
  void _fitToJobs(List<Job> jobs) {
    final fit = _fitAround(jobs);
    if (fit != null) _mapController.fitCamera(fit);
  }

  /// How far from the opening point a job can be and still count as "here".
  ///
  /// Roughly a metropolitan area. It exists because the seed spans Karachi to
  /// Gilgit: framing *everything* opens on the whole country, where every pin
  /// is a dot and none of them is near anybody. "Show all jobs" is right there
  /// for whoever wants that view, and it should be a choice rather than the
  /// thing that happens on launch.
  static const _nearbyMetres = 60000.0;

  /// Works out the opening camera, once, as soon as there are jobs.
  ///
  /// The fixed opening camera used to work because the seed surrounded it.
  /// Since P1-1 a worker sees a subset, sometimes with none of it in the
  /// middle, and an empty map on first launch reads as no work available.
  ///
  /// So: fit to the jobs around wherever the map is starting — the device
  /// position when it is known, the fallback city when it is not. If there is
  /// nothing near, fit everything instead, because a distant pin the user can
  /// see beats a correct view of nothing.
  ///
  /// **Computed here and handed to the map, rather than applied to it after
  /// the fact.** This used to move the camera from a post-frame callback,
  /// which meant the map's first layout happened at one place and its real
  /// position arrived a frame later — and a tile layer that has already
  /// decided which tiles it wants does not always notice. The symptom was a
  /// map that stayed blank until the first pan or zoom, because that was the
  /// first event that made it think again. `initialCameraFit` is resolved by
  /// flutter_map during its own first layout, when the size is genuinely
  /// known, so there is no second position and nothing to miss.
  ///
  /// Runs once. Recomputing would fight a user who has since panned.
  void _frameOnFirstLoad(List<Job> jobs, {JobLocation? from}) {
    if (_openingFit != null || jobs.isEmpty) return;

    final origin = from ?? LocationService.fallback;
    final nearby = jobs
        .where((job) => origin.distanceTo(job.location) <= _nearbyMetres)
        .toList(growable: false);

    _openingFit = _fitAround(nearby.isEmpty ? jobs : nearby);
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
          allJobs: jobs.jobs,
          reachable: reachable,
          showingList: _showingList,
          onToggleView: _toggleView,
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
          openingFit: _openingFit,
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
    required this.allJobs,
    required this.reachable,
    required this.showingList,
    required this.onToggleView,
    required this.jobs,
    required this.totalJobCount,
    required this.hiddenByTags,
    required this.filters,
    required this.selectedJobId,
    required this.location,
    required this.mapController,
    required this.openingFit,
    required this.tilesUnavailable,
    required this.onJobTapped,
    required this.onMapTapped,
    required this.onMyLocationPressed,
    required this.onTilesUnavailable,
    required this.onOpenJob,
    required this.onClusterTapped,
    required this.onFitToJobs,
  });

  /// Every job on the device, and those the visibility rule lets through —
  /// the list's empty states need both to say the right thing.
  final List<Job> allJobs;
  final List<Job> reachable;

  final bool showingList;
  final VoidCallback onToggleView;

  final List<Job> jobs;
  final int totalJobCount;
  final int hiddenByTags;
  final JobFilterController filters;
  final String? selectedJobId;
  final LocationController location;
  final MapController mapController;

  /// The camera the map opens at, resolved by flutter_map at its own first
  /// layout. Null until the jobs have loaded.
  final CameraFit? openingFit;

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
    final split = LayoutSize.of(context).isSplit;

    final viewSwitch = JobsViewSwitch(
      showingMap: !showingList,
      jobCount: jobs.length,
      totalJobCount: totalJobCount,
      onPressed: onToggleView,
    );

    if (!split && showingList) {
      return _ListBody(
        allJobs: allJobs,
        reachable: reachable,
        visible: jobs,
        filters: filters,
        viewerLocation: location.position,
        viewSwitch: viewSwitch,
      );
    }

    final map = _MapBody(
      viewSwitch: split ? null : viewSwitch,
      jobs: jobs,
      totalJobCount: totalJobCount,
      hiddenByTags: hiddenByTags,
      filters: filters,
      selectedJobId: selectedJobId,
      location: location,
      mapController: mapController,
      openingFit: openingFit,
      tilesUnavailable: tilesUnavailable,
      // The preview card is the handset's answer to "what is this pin?". With
      // a rail beside the map that question is already answered, and a card
      // over the map would only cover it.
      showsPreviewCard: !split,
      onJobTapped: onJobTapped,
      onMapTapped: onMapTapped,
      onMyLocationPressed: onMyLocationPressed,
      onTilesUnavailable: onTilesUnavailable,
      onOpenJob: onOpenJob,
      onClusterTapped: onClusterTapped,
      onFitToJobs: onFitToJobs,
    );

    if (!split) return map;

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
            totalJobCount: totalJobCount,
            viewerLocation: location.position,
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
    required this.totalJobCount,
    required this.viewerLocation,
    required this.selectedJobId,
    required this.onSelect,
    required this.onOpen,
  });

  final List<Job> jobs;
  final int totalJobCount;
  final JobLocation? viewerLocation;
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
              BrandSizing.spaceMd + 2,
              BrandSizing.spaceMd,
              BrandSizing.spaceSm + 4,
            ),
            // The count *is* the heading. This list is every result under
            // the filters, wherever it is; it used to be headed "Work on
            // this map" over a map showing one city of them.
            child: _ResultCount(
              shown: jobs.length,
              total: totalJobCount,
              style: theme.textTheme.titleMedium,
            ),
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
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) =>
                        const Divider(indent: BrandSizing.spaceMd),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return JobRow(
                        job: job,
                        now: now,
                        viewerLocation: viewerLocation,
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

/// "16 jobs", or "3 of 16 jobs" while filters hide some — said, so a short
/// list never looks like a bug.
class _ResultCount extends StatelessWidget {
  const _ResultCount({
    required this.shown,
    required this.total,
    required this.style,
  });

  final int shown;
  final int total;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Text(
      shown == total
          ? strings.jobCount(shown)
          : strings.jobCountOf(shown, total),
      style: style?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// The list in place of the map, where only one of them fits.
///
/// Same search bar, same chips, same results: the only thing that changed is
/// how they are drawn. Held to the reading measure, so on a tablet the rows
/// and the bar above them line up rather than stretching.
class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.allJobs,
    required this.reachable,
    required this.visible,
    required this.filters,
    required this.viewerLocation,
    required this.viewSwitch,
  });

  final List<Job> allJobs;
  final List<Job> reachable;
  final List<Job> visible;
  final JobFilterController filters;
  final JobLocation? viewerLocation;
  final Widget viewSwitch;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: ReadableWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BrandSizing.spaceMd,
                      BrandSizing.spaceSm,
                      BrandSizing.spaceMd,
                      BrandSizing.spaceSm,
                    ),
                    child: JobsSearchBar(filters: filters),
                  ),
                  QuickFilterBar(controller: filters),
                  // The same count the map's switch carries, so it does not
                  // disappear when the list is what is showing.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BrandSizing.spaceMd,
                      BrandSizing.spaceSm + 4,
                      BrandSizing.spaceMd,
                      BrandSizing.spaceSm,
                    ),
                    child: _ResultCount(
                      shown: visible.length,
                      total: reachable.length,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: JobResults(
                      all: allJobs,
                      reachable: reachable,
                      visible: visible,
                      filters: filters,
                      viewerLocation: viewerLocation,
                      // Clear of the view switch floating over the bottom.
                      bottomPadding:
                          JobsViewSwitch.height + BrandSizing.spaceXl * 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: BrandSizing.spaceMd,
          child: Center(child: viewSwitch),
        ),
      ],
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({
    required this.viewSwitch,
    required this.jobs,
    required this.totalJobCount,
    required this.hiddenByTags,
    required this.filters,
    required this.selectedJobId,
    required this.location,
    required this.mapController,
    required this.openingFit,
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

  /// Turns the map into the list. Null where both are on screen.
  final Widget? viewSwitch;

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

  /// The camera the map opens at, resolved by flutter_map at its own first
  /// layout. Null until the jobs have loaded.
  final CameraFit? openingFit;

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
    final cardShown = selected != null && showsPreviewCard;
    final locationExplanation = location.explanation(strings);
    final profile = context.watch<ProfileController>();

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
            openingFit: openingFit,
            onJobTapped: onJobTapped,
            onMapTapped: onMapTapped,
            onTilesUnavailable: onTilesUnavailable,
            onClusterTapped: onClusterTapped,
            myAccountId: context.watch<AccountController>().activeId,
          ),
        ),

        // A floating search bar rather than an app bar — the map should reach
        // the top of the screen.
        Positioned(
          left: BrandSizing.spaceMd,
          right: BrandSizing.spaceMd,
          top: padding.top + BrandSizing.spaceSm,
          // The map wants the whole canvas; the cards floating over it do
          // not. Left-aligned rather than centred, so the overlays sit
          // together in one column instead of drifting apart as the window
          // widens.
          child: MapOverlayWidth(
            child: JobsSearchBar(filters: filters, floating: true),
          ),
        ),

        // Quick filters sit under the header, so narrowing the map never
        // means leaving it.
        Positioned(
          left: 0,
          right: 0,
          top: padding.top + MapOverlayWidth.chipsTop,
          // Already a horizontal scroller, so it only needs the same ceiling
          // as the header above it to stay in the same column.
          child: MapOverlayWidth(
            child: QuickFilterBar(controller: filters, floating: true),
          ),
        ),

        // Every notice stacks downward from below the header. One column, not
        // several absolutely-positioned children: two of these can be true at
        // once — no location *and* no tiles, or no matches *and* no trades —
        // and separate Positioned widgets at the same offset would print one
        // on top of the other.
        // **Capped at a third of the height.** Two notices can be true at once,
        // and on a short window they covered most of the map — the one thing
        // the app is for. Past the cap the column scrolls rather than growing.
        //
        // **Not while a pin's preview is up.** That is what was just asked
        // for, and with both on a phone the map between them was a strip
        // about 200px tall. The notices come back when the preview closes.
        if (!cardShown)
          Positioned(
            left: BrandSizing.spaceMd,
            right: BrandSizing.spaceMd,
            top: padding.top + MapOverlayWidth.noticesTop,
            child: MapOverlayWidth(
              clearsMapControls: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height / 3,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    spacing: BrandSizing.spaceSm,
                    children: [
                      if (locationExplanation != null)
                        MapNotice(
                          icon: Icons.location_off_outlined,
                          message: locationExplanation,
                          onDismiss: location.dismissExplanation,
                        ),
                      if (tilesUnavailable)
                        MapNotice(
                          icon: Icons.cloud_off,
                          message: strings.mapImagesNotLoading,
                        ),
                      if (jobs.isEmpty && totalJobCount > 0)
                        MapNotice(
                          icon: Icons.search_off,
                          message: strings.noJobsMatchHere,
                          onDismiss: filters.clear,
                        ),

                      // Not a filter and not an error: the tag rule is holding jobs
                      // back, and the only thing that changes it is adding a trade.
                      // Shown just for a worker who has never added one, so it stops
                      // appearing as soon as it stops being news.
                      //
                      // Dismissible, though closing it changes nothing about the
                      // rule. It sits over the map — the thing the app is for — and
                      // somebody who has read it and is happy on general work should
                      // not have to read it again on every launch. The way back is
                      // the trades screen, which the profile always links to.
                      if (hiddenByTags > 0 && !profile.tradesNoticeDismissed)
                        MapNotice(
                          icon: Icons.construction_outlined,
                          message: strings.noJobsForTradesHelp,
                          actionLabel: strings.addATrade,
                          onAction: () => MyTradesScreen.open(context),
                          onDismiss: profile.dismissTradesNotice,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // The map's own controls ride on top of the preview card instead of
        // sitting at a fixed height above the bottom. The card's height
        // depends on the job — a title on one line or two, a description or
        // none — and at a fixed 236px, "Near me" sat behind a tall one.
        Positioned(
          left: BrandSizing.spaceMd,
          right: BrandSizing.spaceMd,
          // Nothing floats over the bottom of the map any more: posting moved
          // into the navigation bar, and the view switch sits in the middle
          // while these sit at the edge.
          bottom: BrandSizing.spaceMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // On a short window there is no room for both: the controls
              // would be pushed up into the header. The card is what was
              // just asked for, so it wins until it is closed.
              if (!cardShown || MediaQuery.sizeOf(context).height >= 600)
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MapButton(
                        icon: Icons.zoom_out_map,
                        label: strings.showAllJobs,
                        onPressed: jobs.isEmpty
                            ? null
                            : () => onFitToJobs(jobs),
                      ),
                      const SizedBox(height: BrandSizing.spaceSm),
                      MapButton(
                        icon: Icons.my_location,
                        label: strings.nearMeLabel,
                        isBusy: location.isRequesting,
                        onPressed: onMyLocationPressed,
                      ),
                    ],
                  ),
                ),

              // Section 28 — the preview slides up rather than appearing
              // abruptly, and the controls above it move up with it.
              AnimatedSize(
                duration: Motion.standard(context),
                curve: BrandMotion.curve,
                alignment: Alignment.bottomCenter,
                // The card's shadow reaches past its edges.
                clipBehavior: Clip.none,
                child: AnimatedSwitcher(
                  duration: Motion.standard(context),
                  switchInCurve: BrandMotion.curve,
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: !cardShown
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          key: ValueKey(selected.id),
                          padding: const EdgeInsets.only(
                            top: BrandSizing.spaceSm,
                          ),
                          child: Center(
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
              ),
            ],
          ),
        ),

        // The view switch, while there is no preview card: the card is what
        // was just asked for, and the switch would sit on top of it.
        if (viewSwitch != null && !cardShown)
          Positioned(
            left: 0,
            right: 0,
            bottom: BrandSizing.spaceMd,
            child: Center(child: viewSwitch),
          ),
      ],
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
          // The same shape as a row in the list — title and badge on one
          // side, the fare on the other — so a pin and a row read alike.
          LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.displayTitle(strings),
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (job.isPostedBy(
                        context.watch<AccountController>().activeId,
                      )) ...[
                        const SizedBox(height: BrandSizing.spaceXs),
                        const MineBadge(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: BrandSizing.spaceMd),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.42,
                  ),
                  child: FareTag(job: job),
                ),
              ],
            ),
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
              if (job.area != null)
                MetaChip(icon: Icons.place_outlined, label: job.area!),
              if (distance != null)
                MetaChip(icon: Icons.near_me_outlined, label: distance),
              MetaChip(
                icon: Icons.schedule,
                label: Format.scheduled(strings, job.scheduledTime, now),
              ),
              if (job.hasVoiceNote)
                MetaChip(
                  icon: Icons.mic,
                  iconColor: theme.colorScheme.secondary,
                  label: strings.voiceNote,
                ),
              if (job.hasPhotos)
                MetaChip(
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
                child: Text(strings.openDetails),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
