import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/app_version.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';
import '../../services/capture_service.dart';
import '../../services/media_store.dart';
import '../../widgets/state_views.dart';
import 'job_draft_controller.dart';
import 'job_tag_field.dart';
import 'location_picker.dart';
import 'media_fields.dart';
import '../../l10n/app_localizations.dart';

/// Posting a job, and — from Sprint 4 — editing one.
///
/// The form deliberately has no required fields and no asterisks. Voice comes
/// first, then photos, then the optional words: "Every additional field
/// reduces adoption." The save button explains what is still missing rather
/// than silently refusing.
class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({
    super.key,
    required this.initialLocation,
    this.editing,
  });

  /// Where the map opens — the user's position when known.
  final JobLocation initialLocation;

  /// The job being changed, or null when posting a new one.
  final Job? editing;

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  late final CaptureService _capture = CaptureService();
  late final JobDraftController _draft = JobDraftController(
    mediaStore: context.read<MediaStore>(),
    capture: _capture,
    initialLocation: widget.initialLocation,
    editing: widget.editing,
  );

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = _draft.title;
    _descriptionController.text = _draft.description;
    _contactController.text = _draft.contactNumber;
    _fareController.text = _draft.startingFare;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _fareController.dispose();
    _draft.dispose();
    _capture.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final strings = AppStrings.of(context);
    final now = DateTime.now();
    final current = _draft.scheduledTime;

    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: strings.whenIsWorkNeeded,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
      helpText: strings.whatTime,
    );
    if (!mounted) return;

    _draft.setScheduledTime(
      DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      ),
    );
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    final jobs = context.read<JobController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final job = await _draft.build();
    if (job == null) return;

    await jobs.saveJob(job);
    if (!mounted) return;

    navigator.pop(job.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          widget.editing == null
              // Section 33 copy — honest about where it went.
              ? strings.postedOnThisDevice
              : strings.changesSaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final mediaStore = context.read<MediaStore>();

    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.editing == null
                  ? strings.postAJobTitle
                  : strings.editJobTitle,
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: strings.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              BrandSizing.spaceMd,
              BrandSizing.spaceMd,
              BrandSizing.spaceMd,
              BrandSizing.spaceXl * 3,
            ),
            children: [
              Text(
                strings.whatWorkDoYouNeed,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(
                // Section 33 copy — the whole premise, said plainly.
                strings.anyOneIsEnough,
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              VoiceRecorderField(draft: _draft),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel(strings.fieldTags),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(strings.tagsHelp, style: theme.textTheme.labelSmall),
              const SizedBox(height: BrandSizing.spaceSm),
              JobTagField(draft: _draft),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel(strings.photos),
              const SizedBox(height: BrandSizing.spaceSm),
              PhotoField(draft: _draft, mediaStore: mediaStore),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel(strings.fieldTitle),
              const SizedBox(height: BrandSizing.spaceSm),
              TextField(
                controller: _titleController,
                onChanged: _draft.setTitle,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: strings.titleHint),
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel(strings.fieldMessage),
              const SizedBox(height: BrandSizing.spaceSm),
              TextField(
                controller: _descriptionController,
                onChanged: _draft.setDescription,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(hintText: strings.messageHint),
              ),

              // Asked for, never required. Someone who recorded a voice note
              // because writing is hard must still be able to post — that is
              // the product — so this says who the words would help and then
              // gets out of the way.
              if (_draft.wouldBeAudioOnly) ...[
                const SizedBox(height: BrandSizing.spaceSm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hearing_disabled_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: BrandSizing.spaceSm),
                    Expanded(
                      child: Text(
                        strings.addWordsForVoiceNote,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel(strings.fieldStartingFare),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(strings.startingFareHelp, style: theme.textTheme.labelSmall),
              const SizedBox(height: BrandSizing.spaceSm),
              TextField(
                controller: _fareController,
                onChanged: _draft.setStartingFare,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: strings.fareHint,
                  prefixText: '${strings.rupees('').trim()} ',
                ),
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel(strings.fieldContact),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(strings.contactHelp, style: theme.textTheme.labelSmall),
              const SizedBox(height: BrandSizing.spaceSm),
              TextField(
                controller: _contactController,
                onChanged: _draft.setContactNumber,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(hintText: strings.contactHint),
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel(strings.fieldArea),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(strings.areaHelp, style: theme.textTheme.labelSmall),
              const SizedBox(height: BrandSizing.spaceSm),
              LocationPicker(
                location: _draft.location,
                radiusMetres: _draft.radiusMetres,
                onLocationChanged: _draft.setLocation,
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              _RadiusSlider(
                metres: _draft.radiusMetres,
                onChanged: _draft.setRadius,
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel(strings.detailWhen),
              const SizedBox(height: BrandSizing.spaceSm),
              _WhenField(
                scheduledTime: _draft.scheduledTime,
                onPick: _pickDateTime,
                onClear: () => _draft.setScheduledTime(null),
              ),

              if (_draft.saveFailed) ...[
                const SizedBox(height: BrandSizing.spaceLg),
                NoticePanel(
                  message: strings.couldNotSave,
                  icon: Icons.error_outline,
                  tone: NoticeTone.warning,
                ),
              ],

              // Which build this is. Deliberately quiet and at the very
              // bottom: it is for whoever is checking that a change actually
              // deployed, and means nothing to someone posting a job.
              const SizedBox(height: BrandSizing.spaceXl),
              Text(
                AppVersion.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          bottomNavigationBar: _SaveBar(
            draft: _draft,
            isEditing: widget.editing != null,
            onSave: _save,
          ),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // Section 23 — labels stay visible above fields rather than living in the
    // placeholder, and nothing carries a required marker.
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _RadiusSlider extends StatelessWidget {
  const _RadiusSlider({required this.metres, required this.onChanged});

  final double metres;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: metres,
            min: 250,
            max: 5000,
            divisions: 19,
            label: Format.radius(strings, metres),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 82,
          child: Text(
            Format.radius(strings, metres),
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _WhenField extends StatelessWidget {
  const _WhenField({
    required this.scheduledTime,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? scheduledTime;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.event_outlined),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                scheduledTime == null
                    ? strings.anyTime
                    : Format.scheduled(strings, scheduledTime, DateTime.now()),
              ),
            ),
          ),
        ),
        if (scheduledTime != null)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            tooltip: strings.clearTime,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

/// The save bar. When the draft is empty it says what would fix that instead
/// of just disabling itself with no explanation.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.draft,
    required this.isEditing,
    required this.onSave,
  });

  final JobDraftController draft;
  final bool isEditing;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (draft.problem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
                child: Text(
                  draft.problem == DraftProblem.noTags
                      ? strings.tagsRequired
                      : strings.addAtLeastOne,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: draft.canSave ? onSave : null,
                child: draft.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: BrandColours.white,
                        ),
                      )
                    // Section 21 — never "Submit".
                    : Text(isEditing ? strings.saveChanges : strings.saveJob),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
