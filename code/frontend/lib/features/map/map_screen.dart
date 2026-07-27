import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';
import '../../services/media_store.dart';
import '../jobs/filter_bar.dart';
import '../jobs/job_details_sheet.dart';
import '../jobs/job_filter_controller.dart';
import '../../widgets/state_views.dart';
import 'job_map.dart';
import 'location_controller.dart';

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

    _mapController.move(
      LatLng(position.latitude, position.longitude),
      15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobController>();
    final location = context.watch<LocationController>();
    final filters = context.watch<JobFilterController>();

    return Scaffold(
      body: switch (jobs.state) {
        LoadState.idle || LoadState.loading =>
          const LoadingView(message: 'Loading nearby jobs…'),
        LoadState.failed => ErrorView(
            message:
                jobs.errorMessage ?? 'Could not load jobs. Try again.',
            onRetry: jobs.load,
          ),
        LoadState.ready => _MapBody(
            jobs: filters.apply(jobs.jobs, from: location.position),
            totalJobCount: jobs.jobs.length,
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
          ),
      },
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({
    required this.jobs,
    required this.totalJobCount,
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
  });

  final List<Job> jobs;
  final int totalJobCount;
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

  Job? get _selected {
    if (selectedJobId == null) return null;
    for (final job in jobs) {
      if (job.id == selectedJobId) return job;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final selected = _selected;

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
          ),
        ),

        // A floating title rather than an app bar — the map should reach the
        // top of the screen.
        Positioned(
          left: BrandSizing.spaceMd,
          right: BrandSizing.spaceMd,
          top: padding.top + BrandSizing.spaceSm,
          child: _MapHeader(
            jobCount: jobs.length,
            totalJobCount: totalJobCount,
          ),
        ),

        // Quick filters sit under the header, so narrowing the map never
        // means leaving it.
        Positioned(
          left: 0,
          right: 0,
          top: padding.top + 64,
          child: QuickFilterBar(controller: filters),
        ),

        // Notices stack downward from below the header rather than each
        // being positioned absolutely, so two at once cannot overlap.
        Positioned(
          left: BrandSizing.spaceMd,
          right: BrandSizing.spaceMd,
          top: padding.top + 116,
          child: Column(
            children: [
              if (location.explanation != null)
                _MapNotice(
                  icon: Icons.location_off_outlined,
                  message: location.explanation!,
                  onDismiss: location.dismissExplanation,
                ),
              if (tilesUnavailable) ...[
                if (location.explanation != null)
                  const SizedBox(height: BrandSizing.spaceSm),
                const _MapNotice(
                  icon: Icons.cloud_off,
                  message: 'Map images are not loading. Jobs are still shown '
                      'in the right places.',
                ),
              ],
            ],
          ),
        ),

        // "Near Me" sits above the preview card so it never ends up behind it.
        AnimatedPositioned(
          duration: BrandMotion.standard,
          curve: BrandMotion.curve,
          right: BrandSizing.spaceMd,
          bottom: selected != null ? 236 : 96,
          child: _MyLocationButton(
            isBusy: location.isRequesting,
            onPressed: onMyLocationPressed,
          ),
        ),

        if (jobs.isEmpty && totalJobCount > 0)
          Positioned(
            left: BrandSizing.spaceMd,
            right: BrandSizing.spaceMd,
            top: padding.top + 116,
            child: _MapNotice(
              icon: Icons.search_off,
              message: 'No jobs match here. Try a wider area or a different '
                  'time.',
              onDismiss: filters.clear,
            ),
          ),

        // Section 28 — the preview slides up rather than appearing abruptly.
        AnimatedSwitcher(
          duration: BrandMotion.standard,
          switchInCurve: BrandMotion.curve,
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: selected == null
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
                    child: JobPreviewCard(
                      job: selected,
                      viewerLocation: location.position,
                      onOpen: () => onOpenJob(selected),
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
          Icon(Icons.place, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: BrandSizing.spaceSm),
          Expanded(
            child: Text('Nearby work', style: theme.textTheme.titleLarge),
          ),
          Text(
            // Say what is being hidden, so a short list never looks like a
            // bug.
            jobCount == totalJobCount
                ? '$jobCount job${jobCount == 1 ? '' : 's'}'
                : '$jobCount of $totalJobCount',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({
    required this.icon,
    required this.message,
    this.onDismiss,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: BrandColours.informationBlue),
          const SizedBox(width: BrandSizing.spaceSm + 4),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
            ),
        ],
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
                  semanticLabel: 'Near me',
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
    final theme = Theme.of(context);
    final now = DateTime.now();
    final distance = Format.distanceToJob(viewerLocation, job);

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
                  job.displayTitle,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (job.isLocal) ...[
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
                label: Format.scheduled(job.scheduledTime, now),
              ),
              if (distance != null)
                _MetaChip(icon: Icons.near_me_outlined, label: distance),
              _MetaChip(
                icon: Icons.radio_button_unchecked,
                label: Format.radius(job.radiusMetres),
              ),
              if (job.hasVoiceNote)
                const _MetaChip(icon: Icons.mic, label: 'Voice note'),
              if (job.hasPhotos)
                _MetaChip(
                  icon: Icons.photo_library_outlined,
                  label: '${job.photoPaths.length} photo'
                      '${job.photoPaths.length == 1 ? '' : 's'}',
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceSm,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: BrandColours.copper,
        borderRadius: BrandRadius.smallAll,
      ),
      child: const Text(
        'On this device',
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
