import 'dart:math' as math;

import '../../models/job_tag.dart';
import '../../services/ai/ai_agent.dart';
import '../../services/ai/ai_model.dart';
import '../../services/ai/ai_safety.dart';
import 'fare_evidence.dart';
import 'fare_guard.dart';

enum FareAdviceSource {
  /// The quartiles of similar jobs, worked out on the device.
  onDevice,

  /// The AI agent, held to the evidence by [FareGuard].
  agent,
}

/// A suggested starting fare, with what it rests on.
class FareAdvice {
  const FareAdvice({
    required this.low,
    required this.suggested,
    required this.high,
    required this.source,
    this.evidence,
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

  /// What similar work went for. Null when there was none — only possible
  /// from the agent, and said so on screen.
  final FareRange? evidence;

  /// The agent's own explanation, cleaned by [AiSafety.prose].
  final String? reasoning;

  /// Which model answered, so a figure is never shown without its author.
  final String? model;
  final bool modelOnDevice;

  /// [FareGuard] had to pull the agent's figure back inside the evidence.
  final bool clamped;

  /// Set when the AI was asked and could not answer, so this is the estimate
  /// from similar jobs instead. An [AiFailure] code.
  final String? agentFailure;

  /// The tools the agent used, in order — what it looked at before answering.
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

  /// The job as the hirer wrote it, for the agent — framed as data by
  /// [AiAgent]. Never a phone number: the form's contact field is not here.
  String get jobText => [
    if ((title ?? '').isNotEmpty) 'Title: $title.',
    if ((description ?? '').isNotEmpty) 'Description: $description.',
    if ((when ?? '').isNotEmpty) 'When: $when.',
  ].join(' ');
}

/// Answers a [FareQuestion] — from the AI when there is one, from the
/// device's own arithmetic when there is not, and from the arithmetic when
/// the AI fails.
///
/// Never throws. A hirer who asked for help gets the best answer available
/// and is told which one it was.
class FareAdvisor {
  const FareAdvisor({this.guard = const FareGuard()});

  final FareGuard guard;

  /// Look at the evidence, then answer. Three turns is enough for both tools
  /// and an answer; a fourth only gives a small model room to wander.
  static const maxSteps = 3;

  FareAdvice? onDevice(FareRange? range, {String? agentFailure}) =>
      range == null
      ? null
      : FareAdvice(
          low: range.low,
          suggested: range.typical,
          high: range.high,
          source: FareAdviceSource.onDevice,
          evidence: range,
          agentFailure: agentFailure,
        );

  Future<FareAdvice?> advise(FareQuestion question, {AiModel? model}) async {
    final range = question.range;
    if (model == null) return onDevice(range);

    try {
      final outcome = await AiAgent(
        model: model,
        instructions: _instructions(question.language),
        tools: fareTools(question.evidence),
        answer: const {
          'low': {'type': 'integer'},
          'suggested': {'type': 'integer'},
          'high': {'type': 'integer'},
          'reasoning': {'type': 'string'},
        },
        requiredAnswer: const ['low', 'suggested', 'high'],
        maxSteps: maxSteps,
        maxTokens: 220,
      ).run(
        question.jobText,
        context: 'Job tags: ${question.tags.map((t) => t.id).join(', ')}.',
      );

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
      final reasoning = AiSafety.prose(answer['reasoning']);
      return FareAdvice(
        low: held.low,
        suggested: held.suggested,
        high: held.high,
        source: FareAdviceSource.agent,
        evidence: range,
        reasoning: reasoning.isEmpty ? null : reasoning,
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
      "You are Trust Hire's fare adviser. Trust Hire connects people in "
      'Pakistan who need local work done with workers nearby. A hirer is about '
      'to post a job and wants a fair starting fare in Pakistani rupees. '
      'Workers will counter it, so it should be realistic rather than as low '
      'as possible.\n'
      'First call market_summary for the main tag. Use comparable_jobs if you '
      'want examples. Then answer with low, suggested and high in whole '
      'rupees, low <= suggested <= high, based only on what the tools '
      'returned. Agreed fares are what work actually went for; asked fares are '
      'only what hirers opened at. In reasoning, write at most two short '
      'sentences in ${language == 'ur' ? 'Urdu' : 'English'}, and say how many '
      'comparable jobs you relied on.';
}

/// The fare agent's tools: read-only questions over the evidence the device
/// already holds. The same numbers the estimate is made from, so the agent
/// and the estimate can disagree about what the evidence means, never about
/// what it is.
List<AiTool> fareTools(List<FareComparable> evidence) {
  final tagIds = [for (final tag in JobTag.values) tag.id];

  List<FareComparable> withTag(Object? tag) => tag is String &&
          tagIds.contains(tag)
      ? [for (final e in evidence) if (e.tags.any((t) => t.id == tag)) e]
      : evidence;

  return [
    AiTool(
      name: 'market_summary',
      description:
          'Fare statistics in rupees for similar jobs: agreed fares (what '
          'work went for) and asked fares (what hirers opened at). Give a tag '
          'to narrow it.',
      parameters: {
        'tag': {'type': 'string', 'enum': tagIds},
      },
      run: (arguments) {
        final rows = withTag(arguments['tag']);
        return {
          'tag': arguments['tag'] ?? 'all',
          'agreed': _stats([for (final r in rows) if (r.agreed) r.fare]),
          'asked': _stats([for (final r in rows) if (!r.agreed) r.fare]),
        };
      },
    ),
    AiTool(
      name: 'comparable_jobs',
      description:
          'The most similar jobs: title, fare, whether agreed, km away and '
          'days ago. Agreed and nearby first.',
      parameters: {
        'tag': {'type': 'string', 'enum': tagIds},
        'within_km': {'type': 'number'},
        'limit': {'type': 'integer'},
      },
      run: (arguments) {
        var rows = withTag(arguments['tag']);
        final within = arguments['within_km'];
        if (within is num && within > 0) {
          rows = [for (final r in rows) if (r.km != null && r.km! <= within) r];
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
      description: 'How fares and commission work on Trust Hire.',
      run: (_) => const {
        'currency': 'PKR, whole rupees',
        'startingFare': 'an opening offer; workers counter it',
        'agreedFare': 'locked when the hirer accepts an offer',
        'commission': '5% of the agreed fare, paid by the worker',
      },
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
