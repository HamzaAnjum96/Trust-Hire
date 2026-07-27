import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/account_controller.dart';
import 'package:trust_hire/app/rating_controller.dart';
import 'package:trust_hire/features/lifecycle/job_lifecycle.dart';
import 'package:trust_hire/features/ratings/rating_rules.dart';
import 'package:trust_hire/models/account.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/rating.dart';
import 'package:trust_hire/services/local_store.dart';

/// Section 10, and the one asymmetry in it.
///
/// Both sides rate each other; only one of the two ratings is ever shown. A
/// worker's average follows them into every future job, so it is public and
/// it is the thing that decides what they are offered. A hirer's is collected
/// and kept internal, for spotting people who cause trouble — publishing it
/// would turn a labourer's honest complaint into a public accusation against
/// somebody with more standing than they have.
///
/// Most of what follows is about the things the rules **refuse**, because a
/// rating system's failure mode is not a wrong average — it is a score given
/// by somebody who was not there, or given twice, or given for work that
/// never happened.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const rules = RatingRules();
  const somewhere = JobLocation(latitude: 33.7104, longitude: 73.0551);
  final now = DateTime(2026, 7, 27, 10);

  Job job({
    String id = 'job-1',
    JobStatus status = JobStatus.completed,
    String? workerId = 'user-009',
    int? agreedFare = 1800,
  }) => Job(
    id: id,
    location: somewhere,
    createdAt: now,
    tags: const {JobTag.misc},
    status: status,
    acceptedWorkerId: workerId,
    agreedFare: agreedFare,
    postedBy: 'user-003',
  );

  Rating rating(
    String id, {
    String jobId = 'job-1',
    RatedSide side = RatedSide.worker,
    int stars = 5,
  }) => Rating(
    id: id,
    jobId: jobId,
    side: side,
    stars: stars,
    createdAt: now,
  );

  group('who may rate, and when', () {
    test('both sides may, once the job is finished', () {
      expect(
        rules.canRate(job(), role: JobRole.hirer, existing: const []),
        isTrue,
      );
      expect(
        rules.canRate(job(), role: JobRole.worker, existing: const []),
        isTrue,
      );
    });

    test('a bystander may not', () {
      // They were not there. A rating from somebody with no stake in the job
      // is either a mistake or an attack.
      expect(
        rules.canRate(job(), role: JobRole.bystander, existing: const []),
        isFalse,
      );
    });

    test('a cancelled job cannot be rated', () {
      // Nobody did any work. A one-star for a job that never happened is a
      // weapon rather than a signal, and cancelling already has its own
      // consequence in the wallet.
      for (final status in [
        JobStatus.open,
        JobStatus.accepted,
        JobStatus.inProgress,
        JobStatus.cancelled,
        JobStatus.expired,
      ]) {
        expect(
          rules.canRate(
            job(status: status),
            role: JobRole.hirer,
            existing: const [],
          ),
          isFalse,
          reason: 'a $status job should not be ratable',
        );
      }
    });

    test('nobody rates twice', () {
      final given = [rating('r1')];

      expect(rules.canRate(job(), role: JobRole.hirer, existing: given), isFalse);
      // The other side has not gone yet, and is not blocked by the first.
      expect(rules.canRate(job(), role: JobRole.worker, existing: given), isTrue);
    });

    test('the two sides are always opposite', () {
      // You cannot rate yourself. The hirer scores the worker and the worker
      // scores the hirer, and nothing in the API takes "who I am rating" as a
      // separate argument that could be got wrong.
      expect(rules.ratedBy(JobRole.hirer), RatedSide.worker);
      expect(rules.ratedBy(JobRole.worker), RatedSide.hirer);
    });

    test('a score has to be one somebody could have meant', () {
      expect(rules.isValidScore(0), isFalse);
      expect(rules.isValidScore(1), isTrue);
      expect(rules.isValidScore(5), isTrue);
      expect(rules.isValidScore(6), isFalse);
    });
  });

  group("a worker's public record", () {
    test('averages only the ratings of the worker', () {
      // The hirer's ratings sit in the same list. If they leaked into this
      // average, a worker's public number would move when somebody scored the
      // person who hired them.
      final standing = rules.standingFor(
        ratings: [
          rating('r1', stars: 5),
          rating('r2', stars: 3),
          rating('r3', side: RatedSide.hirer, stars: 1),
        ],
        completedJobs: [job()],
      );

      expect(standing.averageStars, 4.0);
    });

    test('an unrated worker shows nothing rather than a zero', () {
      // New is not bad. A zero out of five says the opposite of the truth
      // about somebody who has simply not started yet.
      final standing = rules.standingFor(
        ratings: const [],
        completedJobs: [job()],
      );

      expect(standing.averageStars, isNull);
      expect(standing.hasRating, isFalse);
      expect(standing.hasHistory, isTrue);
    });

    test('the fare average comes from the jobs, not from the ratings', () {
      // A worker who was never rated has still been paid, and a hirer
      // deciding what to offer should see that.
      final standing = rules.standingFor(
        ratings: const [],
        completedJobs: [
          job(id: 'a', agreedFare: 1000),
          job(id: 'b', agreedFare: 2000),
          // No agreed fare — the two sides settled it off the platform. It is
          // not a zero, so it must not drag the average down.
          job(id: 'c', agreedFare: null),
        ],
      );

      expect(standing.completedJobs, 3);
      expect(standing.averageFare, 1500);
    });

    test('a worker with no history has no fare average', () {
      final standing = rules.standingFor(
        ratings: const [],
        completedJobs: const [],
      );

      expect(standing.averageFare, isNull);
      expect(standing.hasHistory, isFalse);
    });
  });

  group('the hirer half is not public', () {
    test('a hirer rating is marked as not public', () {
      expect(RatedSide.hirer.isPublic, isFalse);
      expect(RatedSide.worker.isPublic, isTrue);
    });

    test('reading them takes asking for them by name', () {
      // There is deliberately no general "ratings for this user" accessor.
      // The admin panel in P1-7 asks for internalHirerRatings; nothing else
      // has a way to reach them, so leaking them cannot be a one-word slip.
      final all = [rating('r1'), rating('r2', side: RatedSide.hirer)];

      expect(rules.internalHirerRatings(all), hasLength(1));
      expect(rules.internalHirerRatings(all).single.id, 'r2');
    });

    test('and the public average never contains one', () {
      final standing = rules.standingFor(
        ratings: [rating('r1', side: RatedSide.hirer, stars: 1)],
        completedJobs: [job()],
      );

      expect(
        standing.averageStars,
        isNull,
        reason: 'a hirer rating alone must leave the worker unrated',
      );
    });
  });

  group('the controller', () {
    Future<RatingController> controller() async {
      final store = await LocalStore.open();
      return RatingController(store)..load();
    }

    test('records a rating and survives a reload', () async {
      final store = await LocalStore.open();
      final ratings = RatingController(store)..load();

      final saved = await ratings.rate(
        job(),
        role: JobRole.hirer,
        stars: 4,
        note: '  on time  ',
      );

      expect(saved, isNotNull);
      expect(saved!.side, RatedSide.worker);
      expect(saved.stars, 4);
      expect(saved.note, 'on time', reason: 'the note should be trimmed');

      final reloaded = RatingController(store)..load();
      expect(reloaded.forJob('job-1'), hasLength(1));
    });

    test('an empty note is stored as absent, not as blank', () async {
      final ratings = await controller();
      final saved = await ratings.rate(
        job(),
        role: JobRole.hirer,
        stars: 5,
        note: '   ',
      );

      expect(saved!.note, isNull);
    });

    test('refuses rather than throws', () async {
      // A stale button is a race, not a programming error — by the time it is
      // tapped the screen behind it has usually moved on.
      final ratings = await controller();

      expect(
        await ratings.rate(job(), role: JobRole.hirer, stars: 9),
        isNull,
        reason: 'nine stars is not a score',
      );
      expect(
        await ratings.rate(
          job(status: JobStatus.cancelled),
          role: JobRole.hirer,
          stars: 5,
        ),
        isNull,
      );
      expect(
        await ratings.rate(job(), role: JobRole.bystander, stars: 5),
        isNull,
      );
    });

    test('a second rating from the same side is refused', () async {
      final ratings = await controller();

      expect(await ratings.rate(job(), role: JobRole.hirer, stars: 5), isNotNull);
      expect(await ratings.rate(job(), role: JobRole.hirer, stars: 1), isNull);

      // The other side is still free to rate — the two are independent.
      expect(await ratings.rate(job(), role: JobRole.worker, stars: 3), isNotNull);
      expect(ratings.forJob('job-1'), hasLength(2));
    });

    test('a standing counts only the jobs that worker finished', () async {
      final ratings = await controller();

      final theirs = job(id: 'a', workerId: 'user-009', agreedFare: 2000);
      final somebodyElses = job(id: 'b', workerId: 'user-016', agreedFare: 400);
      final unfinished = job(
        id: 'c',
        workerId: 'user-009',
        status: JobStatus.inProgress,
        agreedFare: 9000,
      );

      await ratings.rate(theirs, role: JobRole.hirer, stars: 5);
      await ratings.rate(somebodyElses, role: JobRole.hirer, stars: 1);

      final standing = ratings.standingFor(
        'user-009',
        jobs: [theirs, somebodyElses, unfinished],
      );

      expect(standing.completedJobs, 1);
      expect(standing.averageStars, 5.0);
      expect(
        standing.averageFare,
        2000,
        reason: 'an unfinished job is not money anybody has been paid',
      );
    });
  });

  test('both sides of one job, on one device', () async {
    // The loop demo accounts were built for, end to end. Hina posts and
    // finishes a job; Usman did the work. Each rates the other, and only one
    // of the two ratings shows up anywhere a person can see.
    final store = await LocalStore.open();
    final accounts = AccountController(store)..load();
    final ratings = RatingController(store)..load();
    const lifecycle = JobLifecycle();

    final finished = job(id: 'job-9', workerId: 'user-009');

    await accounts.switchTo(DemoAccounts.byId('user-003'));
    expect(
      lifecycle.roleFor(finished, viewerId: accounts.activeId),
      JobRole.hirer,
    );
    await ratings.rate(finished, role: JobRole.hirer, stars: 5);

    await accounts.switchTo(DemoAccounts.byId('user-009'));
    expect(
      lifecycle.roleFor(finished, viewerId: accounts.activeId),
      JobRole.worker,
    );
    await ratings.rate(finished, role: JobRole.worker, stars: 2);

    // Usman's public standing carries Hina's five. Hina has no public
    // standing at all — her two stars exist, and no screen can reach them.
    expect(ratings.standingFor('user-009', jobs: [finished]).averageStars, 5.0);
    expect(
      ratings.standingFor('user-003', jobs: [finished]).averageStars,
      isNull,
    );
    expect(rules.internalHirerRatings(ratings.all), hasLength(1));
  });
}
