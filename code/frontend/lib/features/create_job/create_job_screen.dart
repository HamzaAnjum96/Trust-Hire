import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';
import '../../services/capture_service.dart';
import '../../services/media_store.dart';
import '../../widgets/state_views.dart';
import 'job_draft_controller.dart';
import 'job_type_field.dart';
import 'location_picker.dart';
import 'media_fields.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController.text = _draft.title;
    _descriptionController.text = _draft.description;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _draft.dispose();
    _capture.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final current = _draft.scheduledTime;

    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'When is the work needed?',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
      helpText: 'What time?',
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
              ? 'Your job has been posted on this device.'
              : 'Your changes have been saved on this device.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaStore = context.read<MediaStore>();

    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.editing == null ? 'Post a job' : 'Edit job'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
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
                'What work do you need?',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(
                // Section 33 copy — the whole premise, said plainly.
                'Add a voice note, photo, or short message. Any one is enough.',
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              VoiceRecorderField(draft: _draft),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel('Kind of work'),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(
                // Never a "please select" — skipping this is fine, and the
                // marker falls back to what the job carries.
                'Optional. Choosing one makes your job easier to spot on the '
                'map.',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              JobTypeField(draft: _draft),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel('Photos'),
              const SizedBox(height: BrandSizing.spaceSm),
              PhotoField(draft: _draft, mediaStore: mediaStore),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel('Title'),
              const SizedBox(height: BrandSizing.spaceSm),
              TextField(
                controller: _titleController,
                onChanged: _draft.setTitle,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Short title. You can add this later.',
                ),
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel('Message'),
              const SizedBox(height: BrandSizing.spaceSm),
              TextField(
                controller: _descriptionController,
                onChanged: _draft.setDescription,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Anything else worth knowing.',
                ),
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              _FieldLabel('Area'),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(
                'Choose the general area. Your exact location will not be '
                'shown.',
                style: theme.textTheme.labelSmall,
              ),
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
              _FieldLabel('When'),
              const SizedBox(height: BrandSizing.spaceSm),
              _WhenField(
                scheduledTime: _draft.scheduledTime,
                onPick: _pickDateTime,
                onClear: () => _draft.setScheduledTime(null),
              ),

              if (_draft.errorMessage != null) ...[
                const SizedBox(height: BrandSizing.spaceLg),
                NoticePanel(
                  message: _draft.errorMessage!,
                  icon: Icons.error_outline,
                  tone: NoticeTone.warning,
                ),
              ],
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
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: metres,
            min: 250,
            max: 5000,
            divisions: 19,
            label: Format.radius(metres),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 82,
          child: Text(
            Format.radius(metres),
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
                    ? 'Any time'
                    : Format.scheduled(scheduledTime, DateTime.now()),
              ),
            ),
          ),
        ),
        if (scheduledTime != null)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            tooltip: 'Clear time',
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
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (draft.problem == DraftProblem.nothingToShow)
              Padding(
                padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
                child: Text(
                  'Add at least one voice note, photo, or message.',
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
                    : Text(isEditing ? 'Save Changes' : 'Save Job'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
