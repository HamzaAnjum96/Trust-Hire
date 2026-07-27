import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/bid_controller.dart';
import '../../app/job_controller.dart';
import '../../app/profile_controller.dart';
import '../../core/formatters.dart';
import '../../core/map_theme.dart';
import '../../core/tokens.dart';
import '../../models/app_user.dart';
import '../../models/job.dart';
import '../../services/media_store.dart';
import '../../widgets/state_views.dart';
import '../../widgets/voice_note_player.dart';
import '../bidding/offer_list.dart';
import '../bidding/offer_sheet.dart';
import '../create_job/create_job_screen.dart';
import 'contact_panel.dart';
import 'saved_jobs_controller.dart';
import 'photo_gallery.dart';
import '../../l10n/app_localizations.dart';

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
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final distance = Format.distanceToJob(strings, viewerLocation, job);

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
              child: Text(
                job.displayTitle(strings),
                style: theme.textTheme.headlineMedium,
              ),
            ),
            if (job.isLocal) ...[
              const SizedBox(width: BrandSizing.spaceSm),
              const _LocalBadge(),
            ],
            const SizedBox(width: BrandSizing.spaceSm),
            _SaveButton(jobId: job.id),
          ],
        ),
        const SizedBox(height: BrandSizing.spaceXs),
        Text(
          strings.postedAgo(Format.posted(strings, job.createdAt, now)),
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

        // Said plainly, rather than leaving someone who cannot hear the
        // recording to discover for themselves that there is nothing to read.
        if (job.isAudioOnly) ...[
          const SizedBox(height: BrandSizing.spaceSm),
          NoticePanel(
            message: job.hasContact
                ? strings.audioOnlyJobHelp
                : strings.audioOnlyJob,
            icon: Icons.hearing_disabled_outlined,
          ),
        ],

        if (job.supportingDescription != null) ...[
          const SizedBox(height: BrandSizing.spaceMd),
          Text(job.supportingDescription!, style: theme.textTheme.bodyLarge),
        ],

        const SizedBox(height: BrandSizing.spaceLg),
        // Every tag the heading has not already said. A job can carry up to
        // three, and a worker deciding whether to bid wants all of them.
        if (job.supportingTags.isNotEmpty)
          _DetailRow(
            icon: job.supportingTags.first.icon,
            label: strings.detailKindOfWork,
            value: job.supportingTags
                .map((tag) => tag.label(strings))
                .join(' · '),
          ),
        if (job.agreedFare != null)
          _DetailRow(
            icon: Icons.lock_outline,
            label: strings.fieldStartingFare,
            value: strings.agreedAt(Format.fare(strings, job.agreedFare!)),
          )
        else if (job.startingFare != null)
          _DetailRow(
            icon: Icons.payments_outlined,
            label: strings.fieldStartingFare,
            value: strings.startsAt(Format.fare(strings, job.startingFare!)),
          ),
        _DetailRow(
          icon: Icons.schedule,
          label: strings.detailWhen,
          value: Format.scheduled(strings, job.scheduledTime, now),
        ),
        _DetailRow(
          icon: Icons.place_outlined,
          label: strings.fieldArea,
          value: distance == null
              ? Format.radius(strings, job.radiusMetres)
              : '$distance · ${Format.radius(strings, job.radiusMetres)}',
        ),
        if (poster != null)
          _DetailRow(
            icon: Icons.person_outline,
            label: strings.detailPostedBy,
            value: poster!.area == null
                ? poster!.name
                : '${poster!.name} · ${poster!.area}',
          ),

        // Money, before the phone number: from P1-2 the way to take a job is
        // to offer a fare, not to ring the poster.
        const SizedBox(height: BrandSizing.spaceMd),
        const Divider(),
        const SizedBox(height: BrandSizing.spaceMd),
        _Bidding(job: job, viewerLocation: viewerLocation),

        const SizedBox(height: BrandSizing.spaceLg),
        Text(strings.contact, style: theme.textTheme.titleMedium),
        const SizedBox(height: BrandSizing.spaceSm),
        if (job.hasContact)
          ContactPanel(number: job.contactNumber!)
        else
          Text(strings.noContactGiven, style: theme.textTheme.bodyMedium),

        const SizedBox(height: BrandSizing.spaceLg),
        _MapPreview(job: job),
        const SizedBox(height: BrandSizing.spaceSm),
        Text(
          // Section 33 copy — reassure rather than expose.
          strings.generalAreaNotice,
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

/// Bookmarks a job so it can be found again.
///
/// Sits beside the heading rather than at the bottom: deciding to keep a job
/// happens while reading it, not after scrolling past the map.
/// Bidding, from whichever side the viewer is on.
///
/// The hirer of a job sees the offers on it; everyone else sees the way to
/// make one. Both live here rather than in two screens, because a job is one
/// thing and splitting it would mean keeping two layouts in step.
class _Bidding extends StatelessWidget {
  const _Bidding({required this.job, required this.viewerLocation});

  final Job job;
  final JobLocation? viewerLocation;

  @override
  Widget build(BuildContext context) {
    // Posted on this device, so this viewer is its hirer. P1-8 replaces the
    // device check with an account id.
    if (job.isLocal) return OfferList(job: job);

    final profile = context.watch<ProfileController>();
    final bids = context.watch<BidController>();

    return OfferAction(
      job: job,
      refusal: bids.rules.refusalFor(
        job,
        worker: profile.profile,
        from: viewerLocation,
        existingBids: bids.forJob(job.id),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final saved = context.watch<SavedJobsController>();
    final isSaved = saved.isSaved(jobId);

    return IconButton(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final nowSaved = await saved.toggle(jobId);

        messenger.showSnackBar(
          SnackBar(
            content: Text(nowSaved ? strings.jobSaved : strings.jobUnsaved),
          ),
        );
      },
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
      // Colour is never the only cue: the icon fills as well.
      color: isSaved ? Theme.of(context).colorScheme.primary : null,
      tooltip: isSaved ? strings.removeFromSaved : strings.saveThisJob,
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
        builder: (_) =>
            CreateJobScreen(initialLocation: job.location, editing: job),
      ),
    );
    // The sheet watches the controller by id, so it refreshes itself once the
    // edit is saved — no manual reload here.
  }

  Future<void> _delete(BuildContext context) async {
    final strings = AppStrings.of(context);
    final controller = context.read<JobController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BrandRadius.largeAll),
        title: Text(strings.deleteThisJob),
        content: Text(strings.deleteJobExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.keepJob),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BrandColours.errorRed),
            // Section 22 — destructive actions are labelled explicitly, never
            // "Confirm" or "Yes".
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.deleteJob),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.deleteJob(job.id);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(strings.jobDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
            label: Text(strings.editJob),
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
            label: Text(strings.deleteJob),
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
              mapTheme.tileLayer(context),
              mapTheme.tintLayer(),
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
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceSm,
        vertical: 3,
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

/// Shown if the job disappears while its sheet is open — which happens once
/// deleting arrives in Sprint 4.
class _DeletedJobNotice extends StatelessWidget {
  const _DeletedJobNotice();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(BrandSizing.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(strings.jobNoLongerHere, style: theme.textTheme.titleLarge),
          const SizedBox(height: BrandSizing.spaceMd),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }
}
