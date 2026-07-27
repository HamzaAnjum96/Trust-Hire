import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/map_theme.dart';
import '../../core/tokens.dart';
import '../../models/app_user.dart';
import '../../models/job.dart';
import '../../services/media_store.dart';
import '../../widgets/voice_note_player.dart';
import '../create_job/create_job_screen.dart';
import 'photo_gallery.dart';

/// The job details bottom sheet.
///
/// Bottom sheets are the preferred pattern for map details (section 25): they
/// preserve the map behind them, open quickly, and lead with the most useful
/// information. Media comes first — photos, then the voice note — because
/// pictures and voice are how this product expects work to be described.
class JobDetailsSheet extends StatelessWidget {
  const JobDetailsSheet({
    super.key,
    required this.jobId,
    required this.mediaStore,
    this.viewerLocation,
  });

  final String jobId;
  final MediaStore mediaStore;
  final JobLocation? viewerLocation;

  /// Opens the sheet for [jobId]. Returns once it is dismissed.
  static Future<void> open(
    BuildContext context, {
    required String jobId,
    required MediaStore mediaStore,
    JobLocation? viewerLocation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => JobDetailsSheet(
        jobId: jobId,
        mediaStore: mediaStore,
        viewerLocation: viewerLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watching by id rather than taking a Job means an edit or delete in a
    // later sprint is reflected here without reopening the sheet.
    final controller = context.watch<JobController>();
    final job = controller.jobById(jobId);

    if (job == null) {
      return const _DeletedJobNotice();
    }

    final poster = controller.userById(job.postedBy);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => _Body(
        job: job,
        poster: poster,
        mediaStore: mediaStore,
        viewerLocation: viewerLocation,
        scrollController: scrollController,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.job,
    required this.poster,
    required this.mediaStore,
    required this.viewerLocation,
    required this.scrollController,
  });

  final Job job;
  final AppUser? poster;
  final MediaStore mediaStore;
  final JobLocation? viewerLocation;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final distance = Format.distanceToJob(viewerLocation, job);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceSm,
        BrandSizing.spaceMd,
        BrandSizing.spaceXl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(job.displayTitle, style: theme.textTheme.headlineMedium),
            ),
            if (job.isLocal) ...[
              const SizedBox(width: BrandSizing.spaceSm),
              const _LocalBadge(),
            ],
          ],
        ),
        const SizedBox(height: BrandSizing.spaceXs),
        Text(
          'Posted ${Format.posted(job.createdAt, now)}',
          style: theme.textTheme.labelSmall,
        ),

        if (job.hasPhotos) ...[
          const SizedBox(height: BrandSizing.spaceMd),
          PhotoGallery(photos: job.photoPaths, mediaStore: mediaStore),
        ],

        if (job.hasVoiceNote) ...[
          const SizedBox(height: BrandSizing.spaceMd),
          VoiceNotePlayer(
            reference: job.voiceNotePath!,
            mediaStore: mediaStore,
            duration: job.voiceNoteDuration,
          ),
        ],

        if (job.supportingDescription != null) ...[
          const SizedBox(height: BrandSizing.spaceMd),
          Text(job.supportingDescription!, style: theme.textTheme.bodyLarge),
        ],

        const SizedBox(height: BrandSizing.spaceLg),
        _DetailRow(
          icon: Icons.schedule,
          label: 'When',
          value: Format.scheduled(job.scheduledTime, now),
        ),
        _DetailRow(
          icon: Icons.place_outlined,
          label: 'Area',
          value: distance == null
              ? Format.radius(job.radiusMetres)
              : '$distance · ${Format.radius(job.radiusMetres)}',
        ),
        if (poster != null)
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Posted by',
            value: poster!.area == null
                ? poster!.name
                : '${poster!.name} · ${poster!.area}',
          ),

        const SizedBox(height: BrandSizing.spaceMd),
        _MapPreview(job: job),
        const SizedBox(height: BrandSizing.spaceSm),
        Text(
          // Section 33 copy — reassure rather than expose.
          'This is the general area, not an exact address.',
          style: theme.textTheme.labelSmall,
        ),

        // Only jobs created here can be changed. Seeded ones stand in for
        // other people's postings, which nobody else gets to edit.
        if (job.isLocal) ...[
          const SizedBox(height: BrandSizing.spaceLg),
          const Divider(),
          const SizedBox(height: BrandSizing.spaceMd),
          _JobActions(job: job),
        ],
      ],
    );
  }
}

/// Edit and delete, for jobs that live on this device.
class _JobActions extends StatelessWidget {
  const _JobActions({required this.job});

  final Job job;

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => CreateJobScreen(
          initialLocation: job.location,
          editing: job,
        ),
      ),
    );
    // The sheet watches the controller by id, so it refreshes itself once the
    // edit is saved — no manual reload here.
  }

  Future<void> _delete(BuildContext context) async {
    final controller = context.read<JobController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BrandRadius.largeAll,
        ),
        title: const Text('Delete this job?'),
        content: const Text(
          'It will be removed from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Job'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: BrandColours.errorRed,
            ),
            // Section 22 — destructive actions are labelled explicitly, never
            // "Confirm" or "Yes".
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete Job'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.deleteJob(job.id);
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Job deleted from this device.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Job'),
          ),
        ),
        const SizedBox(height: BrandSizing.spaceSm),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _delete(context),
            style: TextButton.styleFrom(
              foregroundColor: BrandColours.errorRed,
              minimumSize: const Size(0, BrandSizing.touchTargetPreferred),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Job'),
          ),
        ),
      ],
    );
  }
}

/// A static map showing where the work is, with its approximate area.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final mapTheme = MapTheme.of(context);
    final centre = LatLng(job.location.latitude, job.location.longitude);

    return ClipRRect(
      borderRadius: BrandRadius.largeAll,
      child: SizedBox(
        height: 160,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: centre,
              initialZoom: 14,
              backgroundColor: mapTheme.backgroundColour,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: mapTheme.tileUrl,
                userAgentPackageName: 'com.trusthire.trust_hire',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              IgnorePointer(
                child: ColoredBox(
                  color: mapTheme.tint.withValues(alpha: mapTheme.tintOpacity),
                  child: const SizedBox.expand(),
                ),
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: centre,
                    radius: job.radiusMetres,
                    useRadiusInMeter: true,
                    color: BrandColours.jobRadiusFill,
                    borderColor: BrandColours.jobRadiusBorder,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: BrandSizing.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: BrandSizing.spaceSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
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
        vertical: 3,
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

/// Shown if the job disappears while its sheet is open — which happens once
/// deleting arrives in Sprint 4.
class _DeletedJobNotice extends StatelessWidget {
  const _DeletedJobNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(BrandSizing.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('This job is no longer here.', style: theme.textTheme.titleLarge),
          const SizedBox(height: BrandSizing.spaceMd),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
