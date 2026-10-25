import '../../models/job_tag.dart';
import '../../services/dev_services.dart';
import 'fare_evidence.dart';
import 'fare_guard.dart';

enum FareAdviceSource {
  /// The quartiles of similar jobs, worked out on the device.
  onDevice,

  /// The fare agent on the dev server, held to the evidence by [FareGuard].
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
    this.clamped = false,
    this.agentFailure,
  });

  final int low;
  final int suggested;
  final int high;
  final FareAdviceSource source;

  /// What similar work went for. Null when there was none — only possible
  /// from the agent, and said so on screen.
  final FareRange? evidence;

  /// The agent's own explanation, in the language it was asked in.
  final String? reasoning;

  /// Which model answered, so a figure is never shown without its author.
  final String? model;

  /// [FareGuard] had to pull the agent's figure back inside the evidence.
  final bool clamped;

  /// Set when the agent was asked and could not answer, so this is the
  /// on-device estimate instead. The code the dev server, or the connection,
  /// gave.
  final String? agentFailure;
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

  /// What the dev server is sent. The job as the hirer wrote it, and the
  /// fares to compare with — never a phone number, and never who anybody is.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'job': <String, dynamic>{
      'title': title ?? '',
      'description': description ?? '',
      'tags': [for (final tag in tags) tag.id],
      'when': when ?? '',
    },
    'evidence': [for (final e in evidence) e.toJson()],
    'baseline': range?.toJson() ?? const <String, dynamic>{},
    'language': language,
  };
}

/// Answers a [FareQuestion] — from the agent when there is one, from the
/// device when there is not, and from the device when the agent fails.
///
/// Never throws. A hirer who asked for help gets the best answer available
/// and is told which one it was, not an error about a server they may not
/// know exists.
class FareAdvisor {
  const FareAdvisor({this.guard = const FareGuard()});

  final FareGuard guard;

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

  Future<FareAdvice?> advise(
    FareQuestion question, {
    DevServicesClient? agent,
  }) async {
    final range = question.range;
    if (agent == null) return onDevice(range);

    try {
      final json = await agent.fareAdvice(question.toJson());
      int? rupees(Object? value) => value is num ? value.round() : null;
      final low = rupees(json['low']);
      final suggested = rupees(json['suggested']);
      final high = rupees(json['high']);
      if (low == null || suggested == null || high == null || low <= 0) {
        throw const DevServicesException('bad_response');
      }

      final held = guard.hold(
        low: low,
        suggested: suggested,
        high: high,
        evidence: range,
      );
      final reasoning = json['reasoning'] is String
          ? (json['reasoning'] as String).trim()
          : null;
      final model = json['model'];
      return FareAdvice(
        low: held.low,
        suggested: held.suggested,
        high: held.high,
        source: FareAdviceSource.agent,
        evidence: range,
        reasoning: reasoning == null || reasoning.isEmpty ? null : reasoning,
        model: model is String ? model : null,
        clamped: held.clamped || json['clamped'] == true,
      );
    } on DevServicesException catch (error) {
      return onDevice(range, agentFailure: error.code);
    }
  }
}
