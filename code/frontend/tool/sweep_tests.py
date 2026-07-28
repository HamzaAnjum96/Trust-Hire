#!/usr/bin/env python3
"""Break each load-bearing rule in turn. Does the suite notice?

`flutter test` proves the app behaves as the tests describe. It cannot prove
the *tests* describe anything: a check aimed at a case that also violates a
neighbouring rule passes whether or not the rule it names still exists. The SQL
side of this repository has `code/backend/tool/sweep_schema.sh`, which found two
such checks — both green from the moment they were written, neither capable of
failing. This is the same idea for the Dart suite.

    python3 tool/sweep_tests.py            # every mutation
    python3 tool/sweep_tests.py wallet     # only those whose name matches

**Not a general mutation framework.** Mutating every operator in the codebase
would take hours and report mostly noise — a changed padding value nobody
asserts on is not a finding. Each mutation below is aimed at a specific promise
the product makes, and is written so that a suite which does not catch it has a
real gap. If you add a rule that decides money, visibility or who sees somebody's
identity document, add a mutation for it here.

Exit code 1 if any mutation survives, so this can gate a change to the rules.
"""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys
from dataclasses import dataclass, field

ROOT = pathlib.Path(__file__).resolve().parent.parent


@dataclass
class Mutation:
    """One promise, and the smallest edit that breaks it."""

    name: str
    promise: str
    path: str
    find: str
    replace: str

    # Which test files could plausibly catch it. Narrowing this is what keeps
    # the sweep to minutes rather than an hour — but a mutation that lists too
    # few files reports a gap that is not there, so when in doubt list more.
    tests: list[str] = field(default_factory=list)

    @property
    def file(self) -> pathlib.Path:
        return ROOT / self.path


MUTATIONS = [
    # --- Section 4: the fare is fixed at acceptance -------------------------
    Mutation(
        name="fare-lock",
        promise="an accepted job cannot be re-accepted at a different fare",
        path="lib/models/job.dart",
        find="""  Job withAcceptedBid({required String workerId, required int fare}) {
    if (isAccepted) return this;""",
        replace="""  Job withAcceptedBid({required String workerId, required int fare}) {
    if (false) return this;""",
        tests=["test/bidding_test.dart", "test/job_model_test.dart",
               "test/lifecycle_test.dart"],
    ),
    Mutation(
        name="own-job",
        promise="nobody bids on their own job",
        path="lib/features/bidding/bidding_rules.dart",
        find="    if (job.isPostedBy(worker.userId)) return BidRefusal.ownJob;",
        replace="    if (false) return BidRefusal.ownJob;",
        tests=["test/bidding_test.dart"],
    ),
    Mutation(
        name="bid-after-acceptance",
        promise="a job that has been taken stops taking offers",
        path="lib/features/bidding/bidding_rules.dart",
        find="""    if (!job.status.isTakingOffers ||
        existingBids.any((b) => b.status == BidStatus.accepted)) {
      return BidRefusal.alreadyAccepted;
    }""",
        replace="""    if (false) {
      return BidRefusal.alreadyAccepted;
    }""",
        tests=["test/bidding_test.dart", "test/lifecycle_test.dart"],
    ),
    Mutation(
        name="wallet-lock-blocks-bidding",
        promise="a worker in debt cannot take more work",
        path="lib/features/bidding/bidding_rules.dart",
        find="    if (walletLocked) return BidRefusal.walletLocked;",
        replace="    if (false) return BidRefusal.walletLocked;",
        tests=["test/bidding_test.dart", "test/wallet_test.dart"],
    ),

    # --- Section 11: the wallet --------------------------------------------
    Mutation(
        name="commission-rate",
        promise="the platform takes 5%, not some other number",
        path="lib/features/wallet/wallet_rules.dart",
        find="  static const commissionPercent = 5;",
        replace="  static const commissionPercent = 7;",
        tests=["test/wallet_test.dart", "test/demo_history_test.dart",
               "test/premium_test.dart"],
    ),
    Mutation(
        name="debt-lockout",
        promise="the lockout triggers on more than one unpaid job",
        path="lib/features/wallet/wallet_rules.dart",
        find="  bool isLockedOut(Wallet wallet) => wallet.unpaidJobs > 1;",
        replace="  bool isLockedOut(Wallet wallet) => wallet.unpaidJobs > 99;",
        tests=["test/wallet_test.dart", "test/bidding_test.dart",
               "test/demo_history_test.dart"],
    ),
    Mutation(
        name="first-job-credit-cap",
        promise="the first-job credit is capped at the commission owed",
        path="lib/features/wallet/wallet_rules.dart",
        find="""      final credit = commission < firstJobCreditTokens
          ? commission
          : firstJobCreditTokens;""",
        replace="      final credit = firstJobCreditTokens;",
        tests=["test/wallet_test.dart"],
    ),

    # --- Section 9: Mode B --------------------------------------------------
    Mutation(
        name="hirer-discount",
        promise="booking in the app is 2.5% cheaper than the listed price",
        path="lib/features/premium/premium_rules.dart",
        find="  static const hirerDiscountTenthsPercent = 25;",
        replace="  static const hirerDiscountTenthsPercent = 0;",
        tests=["test/premium_test.dart", "test/demo_history_test.dart"],
    ),
    Mutation(
        name="mode-b-commission",
        promise="the discount comes out of the platform's cut, not the worker's",
        path="lib/features/premium/premium_rules.dart",
        find="  static const bookingCommissionTenthsPercent = 25;",
        replace="  static const bookingCommissionTenthsPercent = 50;",
        tests=["test/premium_test.dart", "test/wallet_test.dart"],
    ),

    # --- Section 10: ratings ------------------------------------------------
    Mutation(
        name="rate-unfinished",
        promise="only a completed job can be rated",
        path="lib/features/ratings/rating_rules.dart",
        find="    if (job.status != JobStatus.completed) return false;",
        replace="    if (false) return false;",
        tests=["test/rating_test.dart"],
    ),
    Mutation(
        name="rate-twice",
        promise="each side rates once",
        path="lib/features/ratings/rating_rules.dart",
        find="    return !existing.any((r) => r.jobId == job.id && r.side == ratedBy(role));",
        replace="    return true;",
        tests=["test/rating_test.dart"],
    ),
    Mutation(
        name="ratings-asymmetry",
        promise="a hirer's rating never reaches the public average",
        path="lib/features/ratings/rating_rules.dart",
        find="        .where((r) => r.side == RatedSide.worker)",
        replace="        .where((r) => true)",
        tests=["test/rating_test.dart", "test/profile_test.dart"],
    ),

    # --- Section 8: who sees which job --------------------------------------
    Mutation(
        name="tag-visibility",
        promise="a specialty job does not reach a worker who has not opted in",
        path="lib/features/feed/job_visibility.dart",
        find="    if (!overlaps(job.tags, worker.tags)) return false;",
        replace="    if (false) return false;",
        tests=["test/job_visibility_test.dart", "test/bidding_test.dart"],
    ),
    Mutation(
        name="geofence",
        promise="a job outside the geofence does not reach a worker",
        path="lib/features/feed/job_visibility.dart",
        find="    return isWithinGeofence(job, from: from);",
        replace="    return true;",
        tests=["test/job_visibility_test.dart"],
    ),
    Mutation(
        name="direct-booking-is-not-broadcast",
        promise="a Mode B booking reaches one worker and nobody else",
        path="lib/features/feed/job_visibility.dart",
        find="    if (job.isDirectBooking) return job.bookedWorkerId == worker.userId;",
        replace="    if (job.isDirectBooking) return true;",
        tests=["test/job_visibility_test.dart", "test/premium_test.dart"],
    ),
    Mutation(
        # Aimed at the constructor, not at `withoutTag`'s early return. That
        # return is belt-and-braces — deleting it changes nothing observable,
        # because the constructor puts the default tag back — so a mutation
        # there would report a gap that is not one. **The constructor is the
        # rule**, and this is what breaking it looks like.
        name="default-tag",
        promise="general work cannot be switched off",
        path="lib/models/worker_profile.dart",
        find="  }) : tags = {...JobTag.defaultWorkerTags, ...?tags};",
        replace="  }) : tags = {...?tags};",
        tests=["test/profile_test.dart", "test/job_tag_test.dart",
               "test/job_visibility_test.dart"],
    ),

    # --- Sections 5 and 7: the location reveal ------------------------------
    Mutation(
        name="location-reveal",
        promise="an exact location appears only once somebody is on the job",
        path="lib/features/lifecycle/job_lifecycle.dart",
        find="    return job.status.hasWorker;",
        replace="    return true;",
        tests=["test/lifecycle_test.dart", "test/job_details_test.dart"],
    ),
    Mutation(
        name="bystander-sees-nothing",
        promise="somebody uninvolved never sees an exact location",
        path="lib/features/lifecycle/job_lifecycle.dart",
        find="    if (role == JobRole.bystander) return false;",
        replace="    if (false) return false;",
        tests=["test/lifecycle_test.dart", "test/job_details_test.dart"],
    ),

    # --- Sections 2 and 12: identity and oversight --------------------------
    Mutation(
        name="cnic-mask",
        promise="a whole CNIC number never reaches storage",
        path="lib/features/verification/verification_rules.dart",
        find="    return '*****-*****${middle.substring(5)}-$check';",
        replace="    return normalised;",
        tests=["test/verification_test.dart"],
    ),
    Mutation(
        name="cnic-door",
        promise="a CNIC opens only while a dispute names that person",
        path="lib/features/admin/admin_rules.dart",
        find="""  bool mayOpenCnic(String userId, {required Iterable<Dispute> disputes}) =>
      disputes.any(
        (dispute) => dispute.aboutUserId == userId && dispute.isOpen,
      );""",
        replace="""  bool mayOpenCnic(String userId, {required Iterable<Dispute> disputes}) =>
      true;""",
        tests=["test/admin_test.dart"],
    ),
    Mutation(
        name="override-needs-a-reason",
        promise="an override with no reason recorded does not happen",
        path="lib/app/admin_controller.dart",
        find="    if (rules.needsNote(action) && !rules.isUsableNote(trimmed)) return;",
        replace="    if (false) return;",
        tests=["test/admin_test.dart"],
    ),
    Mutation(
        name="audit-log-is-written-first",
        promise="a change that fails still leaves a line saying it was tried",
        path="lib/app/admin_controller.dart",
        find="""    _log = [entry, ..._log];
    notifyListeners();

    await _store.writeCollection(
      StoreKeys.auditLog,
      _log.map((e) => e.toJson()).toList(growable: false),
    );

    await change();""",
        replace="""    await change();

    _log = [entry, ..._log];
    notifyListeners();

    await _store.writeCollection(
      StoreKeys.auditLog,
      _log.map((e) => e.toJson()).toList(growable: false),
    );""",
        tests=["test/admin_test.dart"],
    ),
    Mutation(
        name="sim-mismatch-is-not-a-rejection",
        promise="a name mismatch flags an account rather than stopping it",
        path="lib/features/admin/admin_rules.dart",
        find="        if (a.isFlagged != b.isFlagged) return a.isFlagged ? -1 : 1;",
        replace="        if (a.isFlagged != b.isFlagged) return a.isFlagged ? 1 : -1;",
        tests=["test/admin_test.dart"],
    ),
]


def run(mutation: Mutation) -> bool:
    """True when the suite noticed. Restores the file whatever happens."""
    original = mutation.file.read_text()

    if mutation.find not in original:
        print(f"  ??  {mutation.name}: the code this mutates has moved")
        print(f"      looked in {mutation.path} for:")
        print("      " + mutation.find.strip().splitlines()[0])
        return False

    mutation.file.write_text(original.replace(mutation.find, mutation.replace, 1))
    try:
        result = subprocess.run(
            ["flutter", "test", *mutation.tests],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        return result.returncode != 0
    finally:
        mutation.file.write_text(original)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("filter", nargs="?", default="",
                        help="only run mutations whose name contains this")
    args = parser.parse_args()

    chosen = [m for m in MUTATIONS if args.filter in m.name]
    if not chosen:
        print(f"No mutation matches {args.filter!r}.")
        return 1

    print(f"Breaking {len(chosen)} rules, one at a time.\n")

    survivors = []
    for mutation in chosen:
        caught = run(mutation)
        mark = "ok " if caught else " ! "
        print(f"  {mark} {mutation.name}: {mutation.promise}")
        if not caught:
            survivors.append(mutation)

    print()
    if survivors:
        print(f"{len(survivors)} rule(s) can be broken without the suite noticing:")
        for mutation in survivors:
            print(f"  - {mutation.name} — {mutation.promise}")
        print()
        print("Either add a test that fails when that promise is broken, or —")
        print("if the promise is not one the app actually makes — say so here")
        print("and remove the mutation.")
        return 1

    print(f"All {len(chosen)} promises are held up by at least one test.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
