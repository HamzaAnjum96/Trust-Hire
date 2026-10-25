import '../../models/job_tag.dart';
import 'fare_evidence.dart';

/// A suggested starting fare, with what it rests on.
class FareAdvice {
  const FareAdvice({
    required this.low,
    required this.suggested,
    required this.high,
    required this.evidence,
  });

  final int low;
  final int suggested;
  final int high;

  /// What similar work went for — the whole basis of the suggestion, and
  /// said on screen.
  final FareRange evidence;
}

/// What a hirer is asking about.
class FareQuestion {
  const FareQuestion({required this.tags, required this.evidence});

  final Set<JobTag> tags;
  final List<FareComparable> evidence;

  FareRange? get range => FareRange.of(evidence);
}

/// Answers a [FareQuestion] from the device's own arithmetic: the quartiles
/// of what similar work went for.
///
/// **The AI is paused.** It will explain the number when it returns, through
/// `FareGuard`; until then the suggestion is the evidence and nothing else,
/// which is also what it was always going to be held to.
class FareAdvisor {
  const FareAdvisor();

  FareAdvice? advise(FareQuestion question) {
    final range = question.range;
    if (range == null) return null;
    return FareAdvice(
      low: range.low,
      suggested: range.typical,
      high: range.high,
      evidence: range,
    );
  }
}
