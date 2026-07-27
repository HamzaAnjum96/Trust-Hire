import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/bid_controller.dart';
import 'package:trust_hire/features/bidding/bidding_rules.dart';
import 'package:trust_hire/features/lifecycle/job_lifecycle.dart';
import 'package:trust_hire/models/bid.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/worker_profile.dart';

/// Section 7 (the job's life) and Section 5 (the location reveal).
///
/// These are the same sprint on purpose. Section 5 **replaces a promise the
/// POC made** — that an exact location is never shown — and shipping the
/// behaviour without the copy would leave the app telling people something
/// untrue about where their address goes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const lifecycle = JobLifecycle();
  final now = DateTime(2026, 7, 27, 10);
  const somewhere = JobLocation(latitude: 33.7104, longitude: 73.0551);

  Job job({
    JobStatus status = JobStatus.open,
    bool isLocal = false,
    String? workerId,
    DateTime? createdAt,
  }) => Job(
    id: 'job-1',
    location: somewhere,
    createdAt: createdAt ?? now,
    tags: const {JobTag.misc},
    status: status,
    acceptedWorkerId: workerId,
    isLocal: isLocal,
  );

  group('who is looking', () {
    test('a job posted here belongs to its hirer', () {
      expect(
        lifecycle.roleFor(job(isLocal: true), viewerId: 'me'),
        JobRole.hirer,
      );
    });

    test('the chosen worker is recognised', () {
      expect(
        lifecycle.roleFor(
          job(status: JobStatus.accepted, workerId: 'me'),
          viewerId: 'me',
        ),
        JobRole.worker,
      );
    });

    test('everyone else is a bystander', () {
      expect(lifecycle.roleFor(job(), viewerId: 'me'), JobRole.bystander);
      expect(
        lifecycle.roleFor(
          job(status: JobStatus.accepted, workerId: 'someone-else'),
          viewerId: 'me',
        ),
        JobRole.bystander,
      );
    });
  });

  group('what each side can do', () {
    test('a bystander can do nothing, at any status', () {
      for (final status in JobStatus.values) {
        expect(
          lifecycle.actionsFor(job(status: status), role: JobRole.bystander),
          isEmpty,
          reason: status.id,
        );
      }
    });

    test('the hirer moves the job forward', () {
      expect(
        lifecycle.actionsFor(
          job(status: JobStatus.accepted, isLocal: true),
          role: JobRole.hirer,
        ),
        contains(JobAction.confirmArrival),
      );
      expect(
        lifecycle.actionsFor(
          job(status: JobStatus.inProgress, isLocal: true),
          role: JobRole.hirer,
        ),
        contains(JobAction.markComplete),
      );
    });

    test('the worker can only walk away', () {
      // Letting a worker mark a job complete would let them claim a fare the
      // hirer has not agreed was earned.
      for (final status in [JobStatus.accepted, JobStatus.inProgress]) {
        final actions = lifecycle.actionsFor(
          job(status: status, workerId: 'me'),
          role: JobRole.worker,
        );

        expect(actions, [JobAction.cancel], reason: status.id);
      }
    });

    test('a finished job offers nothing to anybody', () {
      for (final status in [
        JobStatus.completed,
        JobStatus.cancelled,
        JobStatus.expired,
      ]) {
        for (final role in JobRole.values) {
          expect(
            lifecycle.actionsFor(
              job(status: status, isLocal: true),
              role: role,
            ),
            isEmpty,
            reason: '${status.id} / ${role.name}',
          );
        }
      }
    });

    test('an action nobody is allowed resolves to nothing', () {
      // A stale button is a race, not a programming error — the screen behind
      // it has already moved on.
      expect(
        lifecycle.resultOf(
          JobAction.markComplete,
          job: job(status: JobStatus.open, isLocal: true),
          role: JobRole.hirer,
        ),
        isNull,
      );
      expect(
        lifecycle.resultOf(
          JobAction.confirmArrival,
          job: job(status: JobStatus.accepted, workerId: 'me'),
          role: JobRole.worker,
        ),
        isNull,
      );
    });
  });

  group('the way through', () {
    test('open to accepted to under way to finished', () {
      var live = job(isLocal: true);
      expect(live.status, JobStatus.open);

      live = live.withAcceptedBid(workerId: 'w', fare: 1800);
      expect(live.status, JobStatus.accepted);

      live = live.withStatus(
        lifecycle.resultOf(
          JobAction.confirmArrival,
          job: live,
          role: JobRole.hirer,
        )!,
      );
      expect(live.status, JobStatus.inProgress);

      live = live.withStatus(
        lifecycle.resultOf(
          JobAction.markComplete,
          job: live,
          role: JobRole.hirer,
        )!,
      );
      expect(live.status, JobStatus.completed);

      // And the fare that was locked at acceptance came all the way through.
      expect(live.agreedFare, 1800);
      expect(live.acceptedWorkerId, 'w');
    });

    test('editing a job cannot move it through its life', () {
      final live = job(isLocal: true).withAcceptedBid(workerId: 'w', fare: 900);
      expect(live.copyWith(title: 'Changed').status, JobStatus.accepted);
    });

    test('an open job expires; a live one does not', () {
      final stale = job(createdAt: now.subtract(const Duration(days: 9)));
      expect(lifecycle.hasExpired(stale, now: now), isTrue);

      expect(
        lifecycle.hasExpired(
          job(createdAt: now.subtract(const Duration(days: 2))),
          now: now,
        ),
        isFalse,
      );

      // Once somebody is committed the clock stops mattering.
      expect(
        lifecycle.hasExpired(
          job(
            status: JobStatus.accepted,
            createdAt: now.subtract(const Duration(days: 90)),
          ),
          now: now,
        ),
        isFalse,
      );
    });

    test('a status survives storage', () {
      final restored = Job.fromJson(job(status: JobStatus.inProgress).toJson());
      expect(restored.status, JobStatus.inProgress);
    });

    test('a job saved before statuses existed reads sensibly', () {
      // One with a worker on it was accepted; everything else was open.
      final legacyOpen = job().toJson()..remove('status');
      expect(Job.fromJson(legacyOpen).status, JobStatus.open);

      final legacyTaken = job(workerId: 'w').toJson()..remove('status');
      expect(Job.fromJson(legacyTaken).status, JobStatus.accepted);
    });
  });

  group('bidding follows the status', () {
    const rules = BiddingRules();

    test('an open job takes offers', () {
      expect(
        rules.refusalFor(
          job(),
          worker: WorkerProfile(userId: 'w'),
          from: somewhere,
          existingBids: const [],
        ),
        isNull,
      );
    });

    test('a cancelled or expired job does not', () {
      // The status is the authority from P1-3 — a job can stop taking offers
      // without anybody having been accepted.
      for (final status in [
        JobStatus.cancelled,
        JobStatus.expired,
        JobStatus.completed,
        JobStatus.inProgress,
      ]) {
        expect(
          rules.refusalFor(
            job(status: status),
            worker: WorkerProfile(userId: 'w'),
            from: somewhere,
            existingBids: const <Bid>[],
          ),
          BidRefusal.alreadyAccepted,
          reason: status.id,
        );
      }
    });
  });

  group('the location reveal', () {
    test('nobody sees the exact spot while offers are open', () {
      for (final role in JobRole.values) {
        expect(
          lifecycle.revealsExactLocation(job(), role: role),
          isFalse,
          reason: role.name,
        );
      }
    });

    test('both sides see it once a worker is chosen', () {
      final taken = job(status: JobStatus.accepted, workerId: 'w');

      expect(
        lifecycle.revealsExactLocation(taken, role: JobRole.hirer),
        isTrue,
      );
      expect(
        lifecycle.revealsExactLocation(taken, role: JobRole.worker),
        isTrue,
      );
    });

    test('a bystander never sees it, at any status', () {
      // The people who can are the two who agreed to meet.
      for (final status in JobStatus.values) {
        expect(
          lifecycle.revealsExactLocation(
            job(status: status),
            role: JobRole.bystander,
          ),
          isFalse,
          reason: status.id,
        );
      }
    });

    test('it stays revealed after the work is done', () {
      // They met. Hiding the address again would be theatre.
      expect(
        lifecycle.revealsExactLocation(
          job(status: JobStatus.completed, workerId: 'w'),
          role: JobRole.worker,
        ),
        isTrue,
      );
    });

    test('a cancelled job goes back to hiding it', () {
      expect(
        lifecycle.revealsExactLocation(
          job(status: JobStatus.cancelled),
          role: JobRole.hirer,
        ),
        isFalse,
      );
    });
  });

  group('the copy matches the behaviour', () {
    /// The whole reason Section 5 and Section 7 are one sprint. Leaving a
    /// promise in place after it stops being true is worse than never having
    /// made it, so this reads the catalogue and fails if the POC's wording
    /// survives.
    test('no string still promises the exact location is never shown', () {
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;

      final broken = <String>[];
      for (final entry in en.entries) {
        if (entry.key.startsWith('@')) continue;
        final text = (entry.value as String).toLowerCase();

        final claimsNever =
            (text.contains('never shown') ||
                text.contains('will not be shown') ||
                text.contains('is never')) &&
            (text.contains('exact') || text.contains('location'));

        if (claimsNever) broken.add('${entry.key}: ${entry.value}');
      }

      expect(
        broken,
        isEmpty,
        reason: 'Phase 1 reveals the exact spot after acceptance',
      );
    });

    test('the replacement copy says when it is shared', () {
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;

      // Not just "no lie" — the user has to be told the real rule.
      for (final key in [
        'areaHelp',
        'generalAreaNotice',
        'onboardPrivacyNote',
      ]) {
        final text = (en[key] as String).toLowerCase();
        expect(
          text.contains('chosen') ||
              text.contains('choose') ||
              text.contains('shared'),
          isTrue,
          reason: '$key does not say when the location is shared: ${en[key]}',
        );
      }
    });
  });

  test('the controller ids line up with the lifecycle', () {
    // roleFor compares against BidController.localWorkerId; if those two ever
    // disagree, a worker stops recognising their own accepted job.
    final taken = job(
      status: JobStatus.accepted,
      workerId: BidController.localWorkerId,
    );

    expect(
      lifecycle.roleFor(taken, viewerId: BidController.localWorkerId),
      JobRole.worker,
    );
  });
}
