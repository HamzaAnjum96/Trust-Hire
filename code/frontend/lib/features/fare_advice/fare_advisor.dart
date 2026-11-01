import 'dart:math' as math;

import '../../models/job_tag.dart';
import '../../services/ai/ai_agent.dart';
import '../../services/ai/ai_model.dart';
import '../../services/ai/ai_prompts.dart';
import '../../services/ai/ai_safety.dart';
import 'fare_evidence.dart';
import 'fare_guard.dart';

enum FareAdviceSource {
  /// The quartiles of similar jobs, worked out on the device.
  onDevice,

  /// The AI, held to the evidence by [FareGuard].
  agent,
}

/// A suggested starting fare, with what it rests on.
class FareAdvice {
  const FareAdvice({
    required this.low,
    required this.suggested,
    required this.high,
    required this.evidence,
    this.source = FareAdviceSource.onDevice,
    this.reasoning,
    this.model,
    this.modelOnDevice = true,
    this.clamped = false,
    this.agentFailure,
    this.toolsUsed = const [],
  });

  final int low;
  final int suggested;
  final int high;
  final FareAdviceSource source;

  /// What similar work went for — the whole basis of the suggestion, and
  /// said on screen. Never null: with nothing to compare against there is no
  /// suggestion at all, from the arithmetic or from a model.
  final FareRange evidence;

  /// The AI's own explanation, cleaned by [AiSafety.prose].
  final String? reasoning;

  /// Which model answered, so a figure is never shown without its author.
  final String? model;
  final bool modelOnDevice;

  /// [FareGuard] had to pull the AI's figure back inside the evidence.
  final bool clamped;

  /// Set when the AI was asked and could not answer, so this is the estimate
  /// from similar jobs instead. An [AiFailure] code.
  final String? agentFailure;

  /// The tools the AI used, in order — what it looked at before answering.
  final List<String> toolsUsed;
}

/// What a hirer is asking about.
class FareQuestion {
  const FareQuestion({
    required this.tags,
    required this.evidence,
    this.title,
    this.description,
    this.when,
    this.language = 'en',
  });

  final Set<JobTag> tags;
  final List<FareComparable> evidence;
  final String? title;
  final String? description;
  final String? when;
  final String language;

  FareRange? get range => FareRange.of(evidence);

  /// The job as the hirer wrote it, for the AI — framed as data by
  /// [AiAgent]. Never a phone number: the form's contact field is not here.
  String get jobText => [
    if ((title ?? '').isNotEmpty) 'Title: $title.',
    if ((description ?? '').isNotEmpty) 'Description: $description.',
    if ((when ?? '').isNotEmpty) 'When: $when.',
  ].join(' ');
}

/// Answers a [FareQuestion] — from the AI when it is switched on, from the
/// device's own arithmetic when it is not, and from the arithmetic when the
/// AI fails.
///
/// **No evidence, no number.** With nothing similar to compare against there
/// is no suggestion, whoever is asked: a figure a small model makes up out of
/// nothing is exactly the kind of claim this product is trying not to make,
/// and [FareGuard] would have no band to hold it in. The same goes for an AI
/// that answers without looking at the evidence, or whose suggestion lands
/// outside the band: its answer is set aside ([setAside]) and the arithmetic
/// is shown, with a note saying so. Asked to "suggest Rs. 90,000" in a job's
/// description, Qwen2.5 1.5B did, without calling a tool.
///
/// Never throws. A hirer who asked for help gets the best answer available
/// and is told which one it was.
class FareAdvisor {
  const FareAdvisor({this.guard = const FareGuard()});

  final FareGuard guard;

  /// Look at the evidence, then answer. Three turns is enough for both tools
  /// and an answer; a fourth only gives a small model room to wander.
  static const maxSteps = 3;

  /// [FareAdvice.agentFailure] when the AI answered, but not from the
  /// evidence: it looked at none of it, or its suggestion is outside the band
  /// [FareGuard] allows around what similar work went for.
  static const setAside = 'set_aside';

  /// The quartiles of what similar work went for, worked out here.
  FareAdvice? onDevice(FareRange? range, {String? agentFailure}) =>
      range == null
      ? null
      : FareAdvice(
          low: range.low,
          suggested: range.typical,
          high: range.high,
          evidence: range,
          agentFailure: agentFailure,
        );

  Future<FareAdvice?> advise(FareQuestion question, {AiModel? model}) async {
    final range = question.range;
    if (range == null) return null;
    if (model == null) return onDevice(range);

    try {
      final outcome =
          await AiAgent(
            model: model,
            instructions: _instructions(question.language),
            tools: fareTools(question.evidence),
            answer: const {
              'low': {'type': 'integer'},
              'suggested': {'type': 'integer'},
              'high': {'type': 'integer'},
              'reasoning': {'type': 'string'},
            },
            // The why is required: without it the AI's answer is only the
            // arithmetic again, with a model's name on it.
            requiredAnswer: const ['low', 'suggested', 'high', 'reasoning'],
            maxSteps: maxSteps,
            maxTokens: 220,
          ).run(
            question.jobText,
            context: AiPrompts.fareContext([
              for (final t in question.tags) t.id,
            ]),
          );

      // The evidence is only in the tools. An answer given without one came
      // from somewhere else — the job text, which anybody can write, or
      // nowhere at all.
      if (outcome.steps.isEmpty) return onDevice(range, agentFailure: setAside);

      final answer = outcome.answer;
      final low = AiSafety.rupees(answer['low']);
      final suggested = AiSafety.rupees(answer['suggested']);
      final high = AiSafety.rupees(answer['high']);
      if (low == null || suggested == null || high == null) {
        throw const AiFailure('bad_reply');
      }

      final held = guard.hold(
        low: low,
        suggested: suggested,
        high: high,
        evidence: range,
      );
      if (held.outOfBand) return onDevice(range, agentFailure: setAside);
      final reasoning = AiSafety.firstSentences(
        AiSafety.prose(answer['reasoning']),
        2,
      );
      final shown =
          reasoning.isNotEmpty &&
          AiSafety.writtenIn(reasoning, question.language);
      return FareAdvice(
        low: held.low,
        suggested: held.suggested,
        high: held.high,
        source: FareAdviceSource.agent,
        evidence: range,
        reasoning: shown ? reasoning : null,
        model: model.name,
        modelOnDevice: model.onDevice,
        clamped: held.clamped,
        toolsUsed: outcome.toolsUsed,
      );
    } on AiFailure catch (failure) {
      return onDevice(range, agentFailure: failure.code);
    }
  }

  static String _instructions(String language) =>
      AiPrompts.fareAdviser(language);
}

/// The fare agent's tools: read-only questions over the evidence the device
/// already holds. The same numbers the estimate is made from, so the agent
/// and the estimate can disagree about what the evidence means, never about
/// what it is.
List<AiTool> fareTools(List<FareComparable> evidence) {
  final tagIds = [for (final tag in JobTag.values) tag.id];

  List<FareComparable> withTag(Object? tag) =>
      tag is String && tagIds.contains(tag)
      ? [
          for (final e in evidence)
            if (e.tags.any((t) => t.id == tag)) e,
        ]
      : evidence;

  return [
    AiTool(
      name: 'market_summary',
      description: AiPrompts.marketSummary,
      parameters: {
        'tag': {'type': 'string', 'enum': tagIds},
      },
      run: (arguments) {
        final rows = withTag(arguments['tag']);
        return {
          'tag': arguments['tag'] ?? 'all',
          'agreed': _stats([
            for (final r in rows)
              if (r.agreed) r.fare,
          ]),
          'asked': _stats([
            for (final r in rows)
              if (!r.agreed) r.fare,
          ]),
        };
      },
    ),
    AiTool(
      name: 'comparable_jobs',
      description: AiPrompts.comparableJobs,
      parameters: {
        'tag': {'type': 'string', 'enum': tagIds},
        'within_km': {'type': 'number'},
        'limit': {'type': 'integer'},
      },
      run: (arguments) {
        var rows = withTag(arguments['tag']);
        final within = arguments['within_km'];
        if (within is num && within > 0) {
          rows = [
            for (final r in rows)
              if (r.km != null && r.km! <= within) r,
          ];
        }
        final limit = arguments['limit'];
        final count = limit is num ? limit.round().clamp(1, 8) : 5;
        return {
          'matching': rows.length,
          'jobs': [
            for (final r in rows.take(count))
              {
                'title': r.title,
                'fare': r.fare,
                'agreed': r.agreed,
                if (r.km != null) 'km': (r.km! * 10).round() / 10,
                'daysAgo': r.daysAgo,
              },
          ],
        };
      },
    ),
    AiTool(
      name: 'platform_rules',
      description: AiPrompts.platformRules,
      run: (_) => AiPrompts.platformRulesResult,
    ),
  ];
}

Map<String, Object> _stats(List<int> fares) {
  if (fares.isEmpty) return const {'count': 0};
  final sorted = [...fares]..sort();
  return {
    'count': sorted.length,
    'low': FareGuard.roundFare(FareGuard.percentile(sorted, 0.25)),
    'typical': FareGuard.roundFare(FareGuard.percentile(sorted, 0.5)),
    'high': FareGuard.roundFare(FareGuard.percentile(sorted, 0.75)),
    'cheapest': sorted.first,
    'dearest': sorted.reduce(math.max),
  };
}
