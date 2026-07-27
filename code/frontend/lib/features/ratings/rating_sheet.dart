import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rating_controller.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../lifecycle/job_lifecycle.dart';
import 'rating_rules.dart';

/// One person scoring the other, after the work is done.
///
/// Deliberately five stars and a note, and nothing else. Section 10 gives no
/// free-text review that anyone reads publicly — the note goes to the admin
/// panel in P1-7 — because a marketplace where a stranger's paragraph can
/// follow a labourer around is one where a single bad day costs somebody their
/// livelihood.
///
/// **The two sides are not symmetric, and the sheet says so.** A worker's
/// score is shown on their profile; a hirer's is kept internally. Telling
/// each person which of the two they are doing is the difference between a
/// rating and a trap.
class RatingSheet extends StatefulWidget {
  const RatingSheet({super.key, required this.job, required this.role});

  final Job job;
  final JobRole role;

  static Future<void> open(
    BuildContext context, {
    required Job job,
    required JobRole role,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RatingSheet(job: job, role: role),
  );

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  final TextEditingController _note = TextEditingController();
  int _stars = 0;
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _isRatingWorker => widget.role == JobRole.hirer;

  Future<void> _send() async {
    if (_stars == 0 || _sending) return;
    setState(() => _sending = true);

    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final saved = await context.read<RatingController>().rate(
      widget.job,
      role: widget.role,
      stars: _stars,
      note: _note.text,
    );

    if (!mounted) return;
    navigator.pop();

    // Null means the rules refused it — a second rating, a job that was
    // cancelled rather than finished. Silence would look like a failed save,
    // so it is named.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved == null ? strings.alreadyRated : strings.ratingThanks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          0,
          BrandSizing.spaceMd,
          BrandSizing.spaceMd + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.rateThisJob, style: theme.textTheme.titleLarge),
            const SizedBox(height: BrandSizing.spaceXs),
            Text(
              _isRatingWorker ? strings.rateWorker : strings.rateHirer,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: BrandSizing.spaceMd),

            _StarPicker(
              stars: _stars,
              onChanged: (value) => setState(() => _stars = value),
            ),

            const SizedBox(height: BrandSizing.spaceSm),
            Text(
              // Which kind of rating this is, before it is given rather than
              // after. Section 10 keeps a hirer's score internal, and somebody
              // who thought they were writing a public review would have been
              // told the wrong thing about their own words.
              _isRatingWorker
                  ? strings.rateWorkerPublic
                  : strings.rateHirerPrivate,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: BrandSizing.spaceMd),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: strings.rateNoteHint,
                border: const OutlineInputBorder(
                  borderRadius: BrandRadius.mediumAll,
                ),
              ),
            ),

            const SizedBox(height: BrandSizing.spaceMd),
            FilledButton(
              // Disabled until a score is chosen: a rating with no stars is
              // not a rating, and sending one silently as a three would put
              // words in somebody's mouth.
              onPressed: _stars == 0 || _sending ? null : _send,
              child: Text(strings.sendRating),
            ),
          ],
        ),
      ),
    );
  }
}

/// One to five, as taps.
///
/// Each star is its own button with its own label, so the control is usable
/// by somebody who cannot see it — a row of identical unlabelled icons is the
/// commonest way a rating widget fails a screen reader.
class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.stars, required this.onChanged});

  final int stars;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var value = RatingRules.minStars;
                value <= RatingRules.maxStars;
                value++)
              IconButton(
                onPressed: () => onChanged(value),
                iconSize: 36,
                tooltip: strings.starsChosen(value),
                icon: Icon(
                  value <= stars ? Icons.star : Icons.star_border,
                  color: value <= stars
                      ? BrandColours.copper
                      : theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        if (stars > 0)
          Padding(
            padding: const EdgeInsets.only(left: BrandSizing.spaceSm),
            child: Text(
              strings.starsChosen(stars),
              style: theme.textTheme.labelMedium,
            ),
          ),
      ],
    );
  }
}
