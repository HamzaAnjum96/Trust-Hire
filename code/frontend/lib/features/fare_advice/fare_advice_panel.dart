import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job_tag.dart';
import '../../widgets/state_views.dart';
import '../create_job/job_draft_controller.dart';
import 'fare_advisor.dart';
import 'fare_evidence.dart';

/// "What should I offer?", answered under the starting fare field.
///
/// Asked for, never automatic: the fare stays the hirer's to choose, and a
/// suggestion that filled the field by itself would quietly become the price.
/// The answer always says what it rests on — how many jobs, agreed or only
/// asked — because a number without its source is exactly the kind of claim
/// this product is trying not to make.
class FareAdvicePanel extends StatefulWidget {
  const FareAdvicePanel({
    super.key,
    required this.draft,
    required this.onUse,
    this.advisor = const FareAdvisor(),
  });

  final JobDraftController draft;

  /// Puts a fare into the form. The panel never writes the field itself.
  final ValueChanged<int> onUse;

  final FareAdvisor advisor;

  @override
  State<FareAdvicePanel> createState() => _FareAdvicePanelState();
}

class _FareAdvicePanelState extends State<FareAdvicePanel> {
  bool _asked = false;
  FareAdvice? _advice;

  /// The tags the answer was for. Change them and it is an answer to a
  /// different question, so it is taken off the screen.
  Set<JobTag> _askedAbout = const {};

  void _ask() {
    final draft = widget.draft;
    final evidence = FareEvidence.gather(
      context.read<JobController>().jobs,
      tags: draft.tags,
      near: draft.location,
      now: DateTime.now(),
      excludingJobId: draft.editingId,
    );
    setState(() {
      _asked = true;
      _askedAbout = draft.tags;
      _advice = widget.advisor.advise(
        FareQuestion(tags: draft.tags, evidence: evidence),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final hasTags = widget.draft.tags.isNotEmpty;
    final current = _asked && setEquals(_askedAbout, widget.draft.tags);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: hasTags ? _ask : null,
            icon: const Icon(Icons.query_stats),
            label: Text(strings.fareAdviceAsk),
          ),
        ),
        const SizedBox(height: BrandSizing.spaceXs),
        Text(
          hasTags ? strings.fareAdviceOnDevice : strings.fareAdviceNeedsTags,
          style: theme.textTheme.labelSmall,
        ),
        if (current) ...[
          const SizedBox(height: BrandSizing.spaceSm),
          if (_advice case final advice?)
            _AdviceCard(advice: advice, onUse: widget.onUse)
          else
            NoticePanel(message: strings.fareAdviceNothing),
        ],
      ],
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice, required this.onUse});

  final FareAdvice advice;
  final ValueChanged<int> onUse;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final evidence = advice.evidence;
    String rupees(int value) => Format.fare(strings, value);

    return Container(
      padding: const EdgeInsets.all(BrandSizing.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BrandRadius.mediumAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.fareAdviceRange(rupees(advice.low), rupees(advice.high)),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: BrandSizing.spaceXs),
          Text(
            strings.fareAdviceSuggested(rupees(advice.suggested)),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: BrandSizing.spaceSm),
          Text(
            evidence.agreedCount > 0
                ? strings.fareAdviceFromAgreed(evidence.agreedCount)
                : strings.fareAdviceFromAsked(evidence.askedCount),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: BrandSizing.spaceMd),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ElevatedButton(
              onPressed: () => onUse(advice.suggested),
              child: Text(strings.fareAdviceUse(rupees(advice.suggested))),
            ),
          ),
          const SizedBox(height: BrandSizing.spaceSm),
          Text(strings.fareAdviceCaveat, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
