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
    # --- Section 4: what a bid may be ---------------------------------------
    Mutation(
        name="fare-ceiling",
        promise="a mistyped zero is caught before the hirer has to catch it",
        path="lib/features/bidding/bidding_rules.dart",
        find="    if (fare > ceiling) return BidRefusal.fareImplausible;",
        replace="    if (false) return BidRefusal.fareImplausible;",
        tests=["test/bidding_test.dart"],
    ),
    Mutation(
        name="fare-must-be-positive",
        promise="nobody offers to work for nothing",
        path="lib/features/bidding/bidding_rules.dart",
        find="    if (fare <= 0) return BidRefusal.fareNotPositive;",
        replace="    if (false) return BidRefusal.fareNotPositive;",
        tests=["test/bidding_test.dart"],
    ),
    Mutation(
        name="withdrawn-offers-leave-the-list",
        promise="a withdrawn offer is off the hirer's list",
        path="lib/features/bidding/bidding_rules.dart",
        find="    final open = bids.where((b) => b.status != BidStatus.withdrawn).toList();",
        replace="    final open = bids.toList();",
        tests=["test/bidding_test.dart"],
    ),

    # --- Section 7: who may do what to a job --------------------------------
    Mutation(
        name="worker-cannot-finish-a-job",
        promise="only the hirer decides the work was done",
        path="lib/features/lifecycle/job_lifecycle.dart",
        find="      (JobRole.worker, _) => const [JobAction.cancel],",
        replace="      (JobRole.worker, _) => const [JobAction.cancel, JobAction.markComplete],",
        tests=["test/lifecycle_test.dart", "test/job_details_test.dart"],
    ),
    Mutation(
        name="bystander-does-nothing",
        promise="somebody uninvolved has no buttons at all",
        path="lib/features/lifecycle/job_lifecycle.dart",
        find="    if (role == JobRole.bystander) return const [];",
        replace="    if (false) return const [];",
        tests=["test/lifecycle_test.dart", "test/job_details_test.dart"],
    ),
    Mutation(
        name="a-finished-job-is-finished",
        promise="a job that has ended takes no further action",
        path="lib/features/lifecycle/job_lifecycle.dart",
        find="    if (!job.status.isLive) return const [];",
        replace="    if (false) return const [];",
        tests=["test/lifecycle_test.dart"],
    ),

    # --- Section 11: the ledger is the only stored state --------------------
    Mutation(
        name="balance-is-derived",
        promise="the balance is a replay of the entries and nothing else",
        path="lib/models/wallet.dart",
        find="  int get balance => entries.fold(0, (sum, entry) => sum + entry.tokens);",
        replace="  int get balance => 0;",
        tests=["test/wallet_test.dart", "test/demo_history_test.dart"],
    ),
    Mutation(
        name="debt-counts-commissions-only",
        promise="an unpaid job is a commission that took the balance below zero",
        path="lib/models/wallet.dart",
        find="      if (entry.kind == WalletEntryKind.commission && running < 0) {",
        replace="      if (running < 0) {",
        tests=["test/wallet_test.dart", "test/demo_history_test.dart"],
    ),

    # --- Section 9: a subscription that has run out -------------------------
    Mutation(
        name="premium-lapses",
        promise="a subscription that has run out stops being premium",
        path="lib/models/premium.dart",
        find="  bool isActiveAt(DateTime now) => now.isBefore(expiresAt);",
        replace="  bool isActiveAt(DateTime now) => true;",
        tests=["test/premium_test.dart"],
    ),

    # --- WCAG 1.2.1 ---------------------------------------------------------
    Mutation(
        name="audio-only-is-labelled",
        promise="a job describable only by ear says so",
        path="lib/models/job.dart",
        find="  bool get isAudioOnly => hasVoiceNote && !hasTextDescription;",
        replace="  bool get isAudioOnly => false;",
        tests=["test/audio_alternative_test.dart", "test/job_details_test.dart"],
    ),

    # --- P1-5a: an account's things are that account's ----------------------
    Mutation(
        name="saved-jobs-are-per-account",
        promise="switching account does not hand over somebody's saved jobs",
        path="lib/features/jobs/saved_jobs_controller.dart",
        find="  String get _key => StoreKeys.forAccount(StoreKeys.savedJobs, _userId);",
        replace="  String get _key => StoreKeys.savedJobs;",
        tests=["test/saved_jobs_test.dart", "test/account_test.dart"],
    ),
    # --- P1-8b: the backend seam --------------------------------------------
    Mutation(
        name="permanent-refusal-leaves-the-queue",
        promise="a write the server will never take stops blocking the ones behind it",
        path="lib/features/sync/sync_rules.dart",
        find="    if (!refusal.isWorthRetrying) return OutboxDecision.reportAndDrop;",
        replace="    if (!refusal.isWorthRetrying) return OutboxDecision.retry;",
        tests=["test/backend_test.dart"],
    ),
    Mutation(
        name="offline-keeps-the-queue",
        promise="losing the connection loses no work",
        path="lib/app/sync_controller.dart",
        find="      _outbox = [for (final write in ordered) write.retried()];",
        replace="      _outbox = const [];",
        tests=["test/backend_test.dart"],
    ),
    Mutation(
        name="outbox-order",
        promise="writes are offered oldest first, so a bid never precedes its job",
        path="lib/features/sync/sync_rules.dart",
        find="      ..sort((a, b) => a.madeAt.compareTo(b.madeAt));",
        replace="      ..sort((a, b) => b.madeAt.compareTo(a.madeAt));",
        tests=["test/backend_test.dart"],
    ),
    Mutation(
        name="server-wins-on-a-locked-field",
        promise="an offline edit made against an old version does not overwrite the server",
        path="lib/features/sync/sync_rules.dart",
        find="    if (local.baseVersion != remote.version) return false;",
        replace="    if (false) return false;",
        tests=["test/backend_test.dart"],
    ),
    Mutation(
        name="the-fare-lock-holds-at-the-server-too",
        promise="the server refuses a rewritten fare, not only the app",
        path="lib/services/backend/mock_backend.dart",
        find="""    if (was != null && now != was) {
      return RefusalCode.fareIsLocked;
    }""",
        replace="""    if (false) {
      return RefusalCode.fareIsLocked;
    }""",
        tests=["test/backend_test.dart"],
    ),
    Mutation(
        name="append-only-at-the-server",
        promise="the server refuses an edit to a ledger or audit entry",
        path="lib/services/backend/mock_backend.dart",
        find="        if (existing != null) return RefusalCode.recordIsAppendOnly;",
        replace="        if (false) return RefusalCode.recordIsAppendOnly;",
        tests=["test/backend_test.dart"],
    ),
    # This one was added *because* the sweep's own discipline caught the test
    # that was meant to protect it. The first version asserted the chip was no
    # wider than `MetaChip.maxWidth` — the very constant being mutated — so it
    # passed with the cap set to infinity. Compared against the screen instead.
    Mutation(
        name="meta-chip-cap",
        promise="a long area name is cut rather than taking the whole line",
        path="lib/widgets/meta_chip.dart",
        find="  static const maxWidth = 220.0;",
        replace="  static const maxWidth = double.infinity;",
        tests=["test/meta_chip_test.dart"],
    ),
    # And so was this one. The check first compared the text's bottom edge to
    # the height of the *window*, which it never exceeded — the sentence was
    # falling out of the scrolling panel, not off the display. Same lesson:
    # measure against the thing that is actually doing the constraining.
    Mutation(
        name="intro-fits-a-short-window",
        promise="the sentence explaining what the app is fits without scrolling",
        path="lib/features/onboarding/onboarding_screen.dart",
        find="    final isShort = MediaQuery.sizeOf(context).height < _shortWindow;",
        replace="    final isShort = false;",
        tests=["test/surfaces_test.dart"],
    ),
    # The rule this protects was written and tested when Mode B was built, and
    # then had no callers for two sprints — no listing recorded where its
    # worker was, so the radius was decorative. A mutation would have caught
    # nothing back then; the promise had no test, it had a test with no subject.
    Mutation(
        name="the-directory-respects-a-worker's-radius",
        promise="a worker who travels 8km is not shown to a hirer 75km away",
        path="lib/features/premium/premium_rules.dart",
        find="    return workerAt.distanceTo(hirerAt) <= listing.serviceRadiusMetres;",
        replace="    return true;",
        tests=["test/premium_test.dart"],
    ),
    Mutation(
        name="directory-search-excludes",
        promise="searching the directory narrows it",
        path="lib/features/premium/premium_rules.dart",
        find="    if (needle.isEmpty) return true;",
        replace="    if (true) return true;",
        tests=["test/premium_test.dart"],
    ),
    # Not a rule about money or visibility, but the same failure mode: the seed
    # had a second hand-written copy of `fromJson`, and when the model grew a
    # field the copy silently dropped it. Everything still loaded.
    Mutation(
        name="the-seed-keeps-a-worker's-base",
        promise="a seeded listing carries the place its radius is measured from",
        path="lib/models/premium.dart",
        find="""        base: json['base'] == null
            ? null
            : JobLocation.fromJson(json['base'] as Map<String, dynamic>),""",
        replace="        base: null,",
        tests=["test/premium_test.dart"],
    ),

    # --- 0.17.0: the notification feed --------------------------------------
    # The feed is assembled from every job, bid and rating on the device,
    # because that is all a local-first app has. This one line is the whole
    # privacy boundary: without it the app is a public activity log of the
    # marketplace, and it would look completely normal to whoever built it.
    Mutation(
        name="the-feed-reaches-only-the-two-people-involved",
        promise="a stranger hears nothing about somebody else's job",
        path="lib/features/notifications/notification_rules.dart",
        find="    if (!isHirer && !isWorker) return;",
        replace="    if (false) return;",
        tests=["test/notification_test.dart"],
    ),
    # The entry a product is tempted to leave out. Leaving it out means a
    # worker refreshes a job for three days to find out by omission.
    Mutation(
        name="a-worker-is-told-they-lost",
        promise="being passed over is said plainly rather than left to be inferred",
        path="lib/features/notifications/notification_rules.dart",
        find="""          yield AppNotification(
            id: 'bid-${bid.id}-passed',""",
        replace="""          if (false) yield AppNotification(
            id: 'bid-${bid.id}-passed',""",
        tests=["test/notification_test.dart"],
    ),

    # --- 0.18.0: messaging ---------------------------------------------------
    # Every message on the device sits in one list. This check is the only
    # thing between a private conversation and a public one.
    Mutation(
        name="a-thread-is-between-two-people",
        promise="a bystander cannot read or write somebody else's conversation",
        path="lib/features/messaging/messaging_rules.dart",
        find="      JobRole.bystander;",
        replace="      JobRole.bystander || true;",
        tests=["test/messaging_test.dart", "test/notification_test.dart"],
    ),
    # Opening a channel to every bidder turns a job with nine offers into nine
    # conversations the hirer never asked for, and is the obvious way to take a
    # deal off the platform before the platform has done anything for it.
    Mutation(
        name="no-thread-before-somebody-is-chosen",
        promise="messaging opens on acceptance, not during bidding",
        path="lib/features/messaging/messaging_rules.dart",
        find="""  bool isOpen(Job job) =>
      job.acceptedWorkerId != null || job.bookedWorkerId != null;""",
        replace="  bool isOpen(Job job) => true;",
        tests=["test/messaging_test.dart"],
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
