import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ai_controller.dart';
import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job_tag.dart';
import '../../widgets/state_views.dart';
import '../ai/ai_consent.dart';
import '../create_job/job_draft_controller.dart';
import 'fare_advisor.dart';
import 'fare_evidence.dart';

/// "What should I offer?", answered under the starting fare field.
///
/// Asked for, never automatic: the fare stays the hirer's to choose, and a
/// suggestion that filled the field by itself would quietly become the price.
/// The answer always says where it came from — the AI and which model, or the
/// arithmetic on similar jobs and how many — because a number without its
/// source is exactly the kind of claim this product is trying not to make.
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
  bool _asking = false;
  bool _asked = false;
  FareAdvice? _advice;

  /// The tags the answer was for. Change them and it is an answer to a
  /// different question, so it is taken off the screen.
  Set<JobTag> _askedAbout = const {};

  Future<void> _ask() async {
    final draft = widget.draft;
    final ai = context.read<AiController>();
    final language = AppStrings.of(context).localeName;

    final evidence = FareEvidence.gather(
      context.read<JobController>().jobs,
      tags: draft.tags,
      near: draft.location,
      now: DateTime.now(),
      excludingJobId: draft.editingId,
    );

    setState(() {
      _asking = true;
      _askedAbout = draft.tags;
    });

    // Starts the model if it is switched on and not yet running; null when it
    // is off, cannot run here, or will not start — the arithmetic answers
    // then.
    final model = await ai.ensureReady();
    if (!mounted) return;

    final advice = await widget.advisor.advise(
      FareQuestion(
        tags: draft.tags,
        evidence: evidence,
        title: draft.title.trim(),
        description: draft.description.trim(),
        when: draft.scheduledTime?.toIso8601String(),
        language: language,
      ),
      model: model,
    );
    if (!mounted) return;

    if (model != null && advice != null) {
      switch (advice.agentFailure) {
        case null:
          ai.noteAnswered();
        case FareAdvisor.setAside:
          break;
        case final failure:
          ai.noteProblem(failure, advice.agentFailureDetail);
      }
    }

    setState(() {
      _asking = false;
      _asked = true;
      _advice = advice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final ai = context.watch<AiController>();
    final hasTags = widget.draft.tags.isNotEmpty;
    final current = _asked && setEquals(_askedAbout, widget.draft.tags);
    final aiOn = ai.enabled && ai.available && ai.state != AiState.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: hasTags && !_asking ? _ask : null,
            icon: const Icon(Icons.query_stats),
            label: Text(strings.fareAdviceAsk),
          ),
        ),
        const SizedBox(height: BrandSizing.spaceXs),
        Text(
          !hasTags
              ? strings.fareAdviceNeedsTags
              : aiOn
              ? (ai.onDevice
                    ? strings.fareAdviceByAi(ai.modelName)
                    : strings.fareAdviceByRemoteAi(ai.modelName))
              : strings.fareAdviceOnDevice,
          style: theme.textTheme.labelSmall,
        ),
        // The way to an explanation, offered where the explanation would go
        // — not buried in settings — and only where the AI can run.
        if (hasTags && ai.available && !ai.enabled)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => askToTurnOnAi(context),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              icon: const Icon(Icons.download_for_offline_outlined, size: 18),
              label: Text(strings.fareAdviceTurnOnAi),
            ),
          ),

        if (_asking) ...[
          const SizedBox(height: BrandSizing.spaceSm),
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: BrandSizing.spaceSm),
              Expanded(
                child: Text(
                  aiOn
                      ? strings.fareAdviceAsking(ai.modelName)
                      : strings.fareAdviceOnDevice,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ] else if (current) ...[
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
    final model = advice.model;
    String rupees(int value) => Format.fare(strings, value);

    return Container(
      padding: const EdgeInsets.all(BrandSizing.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BrandRadius.largeAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One similar job is one figure, not a range from it to itself.
          Text(
            advice.low == advice.high
                ? rupees(advice.low)
                : strings.fareAdviceRange(
                    rupees(advice.low),
                    rupees(advice.high),
                  ),
            style: theme.fareStyle,
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

          // The AI's explanation, under its author's name — never without it.
          if (advice.reasoning != null && model != null) ...[
            const SizedBox(height: BrandSizing.spaceMd),
            Text(
              strings.fareAdviceReasoningBy(model),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: BrandSizing.spaceXs),
            Text(advice.reasoning!, style: theme.textTheme.bodyMedium),
          ],

          if (advice.clamped) ...[
            const SizedBox(height: BrandSizing.spaceSm),
            Text(strings.fareAdviceClamped, style: theme.textTheme.labelSmall),
          ],

          // Asked, and could not answer or was not believed: said, rather
          // than swapping in the arithmetic as though nothing happened.
          if (advice.agentFailure != null) ...[
            const SizedBox(height: BrandSizing.spaceSm),
            NoticePanel(
              message: switch (advice.agentFailure) {
                'timeout' => strings.fareAiFellBackSlow,
                FareAdvisor.setAside => strings.fareAiSetAside,
                _ => strings.fareAiFellBack,
              },
              icon: Icons.info_outline,
            ),
          ],

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
