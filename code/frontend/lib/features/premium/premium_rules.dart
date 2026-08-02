import '../../models/job.dart';
import '../../models/job_tag.dart';
import '../../models/premium.dart';

/// How a hirer has asked to see the directory.
///
/// **The reader's choice, never the platform's.** [byName] is the default and
/// stays the default: a directory that arrives sorted by price teaches workers
/// to undercut each other, and one sorted by anything purchasable is an
/// advertisement wearing a sort control. Offering the same orders as *options*
/// costs none of that, because the hirer is the one who asked.
enum DirectoryOrder {
  /// Alphabetical. Arbitrary, and arbitrary is the point.
  byName,

  /// Closest first. Only meaningful once the hirer's position is known;
  /// workers with no base sort last rather than first.
  byDistance,

  /// Cheapest first, by the lowest price on the menu. A worker with no menu
  /// sorts last rather than sorting as free.
  byPrice,
}

/// Section 9, as rules.
///
/// Pure functions over plain data, like visibility, bidding, the lifecycle and
/// ratings before it. Two of the things here decide what money changes hands,
/// so they should be checkable without a widget.
class PremiumRules {
  const PremiumRules();

  /// What the directory costs. Section 9 says "monthly/yearly" and names no
  /// price, so these are chosen to be recognisable rather than researched:
  /// Rs. 1,000 a month is roughly one small job, and the year is ten months'
  /// money for twelve — a discount big enough to be worth the commitment and
  /// small enough not to look like the monthly price is a trap.
  static const monthlyTokens = 1000;
  static const yearlyTokens = 10000;

  int priceOf(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.monthly => monthlyTokens,
    SubscriptionPlan.yearly => yearlyTokens,
  };

  /// The hirer's discount on a Mode B booking, in tenths of a percent.
  ///
  /// **2.5%, and the spec contradicts itself about who pays for it.** Section
  /// 9 says the platform "keeps 2.5% and passes the other 2.5% back to the
  /// hirer", that "the worker's cost is unaffected", and — in the same
  /// sentence — that workers "still pay the standard 5% commission regardless
  /// of mode". Those three cannot all be true. On a Rs. 3,000 service:
  ///
  /// - Mode A: the worker is paid 3,000, is charged 150, and nets **2,850**.
  /// - Mode B, charging 5%: the hirer pays 2,925, the worker is charged 150,
  ///   and nets 2,775 — so the worker funds the discount, which the spec
  ///   explicitly says they do not.
  /// - Mode B, charging 2.5%: the hirer pays 2,925, the worker is charged 75,
  ///   and nets **2,850** — identical to Mode A.
  ///
  /// The third is the only reading where "the worker's cost is unaffected" is
  /// true and where the platform is the one splitting *its own* take, which is
  /// what the leakage argument requires: booking in the app has to be cheaper
  /// than booking the same worker outside it, and it cannot be the worker who
  /// pays for that or they will simply raise their listed price.
  ///
  /// So the commission on a Mode B booking is half the usual rate, and the
  /// worker's take-home is the same in both modes. If the literal "5%"
  /// reading is ever wanted instead, it is one constant here.
  static const hirerDiscountTenthsPercent = 25;

  /// What the hirer pays for a service listed at [listedFare].
  ///
  /// Rounds down, in the hirer's favour — the same direction the commission
  /// rounds, and for the same reason.
  int priceForHirer(int listedFare) =>
      listedFare - discountOn(listedFare);

  /// The rupees knocked off, so a screen can show the saving rather than only
  /// a smaller number. A discount nobody can see does not prevent leakage.
  int discountOn(int listedFare) =>
      (listedFare * hirerDiscountTenthsPercent) ~/ 1000;

  /// The commission rate on a Mode B booking, in tenths of a percent.
  ///
  /// Half the Mode A 5% — see [hirerDiscountTenthsPercent] for the arithmetic.
  /// Written here rather than derived from [WalletRules] so the dependency
  /// runs one way: the wallet asks the premium rules what a booking costs, and
  /// the premium rules do not need to know how the wallet stores it.
  static const bookingCommissionTenthsPercent = 25;

  /// The commission a worker owes on a Mode B booking of [listedFare].
  ///
  /// Computed from the **listed** price rather than from what the hirer paid,
  /// because the listed price is the number the worker chose and the one their
  /// take-home should be measured against.
  int commissionOnBooking(int listedFare) =>
      (listedFare * bookingCommissionTenthsPercent) ~/ 1000;

  /// Whether this worker should turn up in a directory search now.
  ///
  /// **The whole of Section 9's lapse handling is this one check.** A lapsed
  /// subscription stops future searches and touches nothing else: jobs already
  /// booked run to completion, and Mode A bidding is unaffected, because
  /// neither of those asks this question.
  bool appearsInDirectory(DirectoryListing listing, {required DateTime now}) {
    final subscription = listing.subscription;
    if (subscription == null) return false;
    if (!subscription.isActiveAt(now)) return false;

    // A listing with no services is a name and nothing to book. Hiding it is
    // kinder to the hirer than a directory of dead ends, and kinder to the
    // worker than being seen at their least convincing.
    return listing.hasServices;
  }

  /// Whether [listing]'s worker will travel to [hirerAt].
  ///
  /// An unknown position on *either* side stands the radius down rather than
  /// emptying the directory — the same call the Mode A geofence makes, and
  /// for the same reason: somebody who declined location should lose sorting,
  /// not lose access. A worker who never said where they are keeps the shelf
  /// they paid for.
  ///
  /// **Measured from the listing's own base**, which is why
  /// [DirectoryListing.base] exists. This used to take the worker's position
  /// as a separate argument, alongside a `workerLocations` map threaded down
  /// from the caller — and every caller passed null, because there was
  /// nowhere for a worker's location to be stored. The rule was tested and
  /// unreachable.
  bool reaches(DirectoryListing listing, {required JobLocation? hirerAt}) {
    if (listing.remoteOnly) return true;

    final workerAt = listing.base;
    if (workerAt == null || hirerAt == null) return true;

    return workerAt.distanceTo(hirerAt) <= listing.serviceRadiusMetres;
  }

  /// How far [listing]'s worker is from [hirerAt], or null when either end is
  /// unknown. Null means "do not claim a distance", never zero.
  double? distanceFrom(DirectoryListing listing, {JobLocation? hirerAt}) {
    final workerAt = listing.base;
    if (workerAt == null || hirerAt == null) return null;

    return workerAt.distanceTo(hirerAt);
  }

  /// The directory, filtered and ordered.
  ///
  /// **The default order is nothing the platform can sell.** Cheapest first
  /// would push people into undercutting each other, and "featured" would make
  /// the order a second thing to pay for — Section 9 already charges for being
  /// present, and charging twice for the same shelf is how a directory becomes
  /// a racket. So the default is the order the caller supplied, which is
  /// alphabetical: arbitrary, and arbitrary is the point.
  ///
  /// A hirer may still *ask* for a different order, and [DirectoryOrder] is
  /// how. That is not the same thing: a sort the reader chose is a tool, and a
  /// sort the platform chose is an advertisement. Nothing here is ever ordered
  /// by who paid the most.
  List<DirectoryListing> directory(
    Iterable<DirectoryListing> listings, {
    required DateTime now,
    JobTag? tag,
    JobLocation? hirerAt,
    bool onlyWithinReach = true,
    DirectoryOrder order = DirectoryOrder.byName,
    String? query,
    Map<String, String> names = const <String, String>{},
  }) {
    final matched =
        listings
            .where((listing) => appearsInDirectory(listing, now: now))
            .where((listing) => tag == null || listing.tags.contains(tag))
            .where(
              (listing) =>
                  !onlyWithinReach || reaches(listing, hirerAt: hirerAt),
            )
            .where(
              (listing) =>
                  matchesQuery(listing, query, name: names[listing.workerId]),
            )
            .toList();

    switch (order) {
      case DirectoryOrder.byName:
        break;
      case DirectoryOrder.byDistance:
        // A worker with no base sorts last rather than first. Unknown is not
        // near, and putting it at the top would make "nearest" a lie in
        // exactly the cases the hirer cannot check.
        matched.sort((a, b) {
          final da = distanceFrom(a, hirerAt: hirerAt);
          final db = distanceFrom(b, hirerAt: hirerAt);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      case DirectoryOrder.byPrice:
        // Same reasoning: no menu means no price to compare, so it sorts last
        // instead of sorting as free.
        matched.sort((a, b) {
          final pa = a.fromPrice;
          final pb = b.fromPrice;
          if (pa == null && pb == null) return 0;
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.compareTo(pb);
        });
    }

    return List.unmodifiable(matched);
  }

  /// Whether [listing] matches what the hirer typed.
  ///
  /// Reaches the worker's name, their headline and the titles on their menu —
  /// the three things actually shown on the card. **Not the tag labels**,
  /// which the chip row above already filters by; matching those too would
  /// make typing "cleaning" and tapping Cleaning quietly different searches.
  ///
  /// An empty query matches everything, so the caller never has to special-
  /// case a blank field.
  bool matchesQuery(DirectoryListing listing, String? query, {String? name}) {
    final needle = query?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return true;

    bool has(String? text) => (text ?? '').toLowerCase().contains(needle);

    return has(name) ||
        has(listing.headline) ||
        listing.services.any(
          (service) => has(service.title) || has(service.description),
        );
  }

  /// Whether a hirer may book [service] from [listing] right now.
  ///
  /// A booking made against a listing that has since lapsed is refused rather
  /// than honoured: the price and the radius were part of a live offer, and
  /// resurrecting them from a stale screen would let a hirer hold a worker to
  /// terms they have stopped offering.
  bool canBook(
    DirectoryListing listing, {
    required ServiceOffering service,
    required DateTime now,
  }) =>
      appearsInDirectory(listing, now: now) &&
      listing.serviceById(service.id) != null;

  /// A subscription bought now.
  Subscription start(SubscriptionPlan plan, {required DateTime now}) =>
      Subscription(
        plan: plan,
        startedAt: now,
        expiresAt: now.add(Duration(days: plan.days)),
      );

  /// A subscription renewed. Time is added to whatever is left rather than
  /// starting from today, so renewing early never costs a worker days.
  Subscription renew(
    Subscription? existing,
    SubscriptionPlan plan, {
    required DateTime now,
  }) {
    final from = (existing != null && existing.isActiveAt(now))
        ? existing.expiresAt
        : now;

    return Subscription(
      plan: plan,
      startedAt: existing?.startedAt ?? now,
      expiresAt: from.add(Duration(days: plan.days)),
    );
  }
}
