import 'dart:math' as math;

import 'fare_evidence.dart';

/// A fare proposal after the guard has had it.
class HeldFare {
  const HeldFare(this.low, this.suggested, this.high, {this.clamped = false});

  final int low;
  final int suggested;
  final int high;

  /// The band had to move at least one of the three.
  final bool clamped;
}

/// What a language model is not trusted with: the number itself.
///
/// The fare agent decides which evidence to look at and writes the
/// explanation, but whatever it proposes comes through here before anybody
/// sees it — put in order, rounded the way people price work, and held inside
/// a band around what similar work actually went for. A small model that
/// writes Rs. 900,000 for a leaking tap is stopped here, not shown to somebody
/// about to post a job.
///
/// **Ready for the AI, which is paused.** Nothing proposes a fare for this to
/// hold yet — the suggestion is the arithmetic in `FareRange` — but when the
/// on-device model returns, its figure comes through here before anybody
/// sees it. Kept, and tested, so that rule is already in place when it does.
class FareGuard {
  const FareGuard();

  /// Nothing leaves [low × bandBelow, high × bandAbove] once there are
  /// [minEvidence] agreed fares behind the range. Wide enough for a model to
  /// argue a job is unusual; narrow enough that a misplaced zero cannot get
  /// through.
  static const bandBelow = 0.5;
  static const bandAbove = 1.5;
  static const minEvidence = 3;

  /// To the step a person would price in — Rs. 2,550, not Rs. 2,537.
  static int roundFare(num rupees) {
    final step = rupees < 5000 ? 50 : (rupees < 20000 ? 100 : 500);
    return math.max(step, (rupees / step + 0.5).floor() * step);
  }

  /// Linear interpolation between closest ranks, over a sorted list.
  static double percentile(List<int> sorted, double fraction) {
    if (sorted.isEmpty) return 0;
    final position = (sorted.length - 1) * fraction;
    final lower = position.floor();
    final upper = math.min(lower + 1, sorted.length - 1);
    final weight = position - lower;
    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
  }

  HeldFare hold({
    required int low,
    required int suggested,
    required int high,
    FareRange? evidence,
  }) {
    var lo = math.min(low, high);
    var hi = math.max(low, high);
    var mid = suggested.clamp(lo, hi);

    // A range of one number is not a range. Small models collapse it often,
    // and the evidence's own spread is a better answer than false precision.
    if (lo == hi && evidence != null) {
      lo = math.min(evidence.low, mid);
      hi = math.max(evidence.high, mid);
    }

    lo = roundFare(lo);
    mid = roundFare(mid);
    hi = roundFare(hi);

    if (evidence == null || evidence.agreedCount < minEvidence) {
      return HeldFare(lo, mid, hi);
    }

    final floor = (evidence.low * bandBelow).floor();
    final ceiling = (evidence.high * bandAbove).ceil();
    int band(int value) => value.clamp(floor, ceiling);

    final held = HeldFare(band(lo), band(mid), band(hi));
    return HeldFare(
      held.low,
      held.suggested,
      held.high,
      clamped: held.low != lo || held.suggested != mid || held.high != hi,
    );
  }
}
