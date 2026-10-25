import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/job_controller.dart';
import 'package:trust_hire/features/create_job/create_job_screen.dart';
import 'package:trust_hire/features/fare_advice/fare_advisor.dart';
import 'package:trust_hire/features/fare_advice/fare_evidence.dart';
import 'package:trust_hire/features/fare_advice/fare_guard.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

import 'support/harness.dart';

/// The fare suggestion: what it rests on, and what it is not trusted with.
///
/// The guard is for the AI, which is paused: whatever a model proposes will
/// be held to it. It is tested now so the rule is settled before anything
/// depends on it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  final now = DateTime(2026, 10, 24, 10);
  const here = JobLocation(latitude: 33.70, longitude: 73.05);

  Job job(
    String id, {
    Set<JobTag> tags = const {JobTag.plumbing},
    int? starting,
    int? agreed,
    JobStatus status = JobStatus.open,
    double lat = 33.70,
    int daysAgo = 1,
  }) => Job(
    id: id,
    location: JobLocation(latitude: lat, longitude: 73.05),
    createdAt: now.subtract(Duration(days: daysAgo)),
    title: 'Job $id',
    tags: tags,
    startingFare: starting,
    agreedFare: agreed,
    acceptedWorkerId: agreed == null ? null : 'worker',
    status: agreed == null
        ? status
        : (status == JobStatus.open ? JobStatus.completed : status),
    contactNumber: '0300 1234567',
    postedBy: 'hirer-$id',
  );

  const range = FareRange(
    low: 2000,
    typical: 2500,
    high: 3000,
    agreedCount: 6,
    askedCount: 0,
  );

  group('the guard', () {
    const guard = FareGuard();

    test('rounds the way work is priced', () {
      expect(FareGuard.roundFare(2537), 2550);
      expect(FareGuard.roundFare(12340), 12300);
      expect(FareGuard.roundFare(61200), 61000);
      expect(FareGuard.roundFare(10), 50);
    });

    test('puts a jumbled proposal in order', () {
      final held = guard.hold(
        low: 3000,
        suggested: 5000,
        high: 2000,
        evidence: range,
      );
      expect([held.low, held.high], [2000, 3000]);
      expect(held.suggested, inInclusiveRange(held.low, held.high));
    });

    test('a misplaced zero cannot get through', () {
      var held = guard.hold(
        low: 20000,
        suggested: 25000,
        high: 30000,
        evidence: range,
      );
      expect(held.clamped, isTrue);
      expect(held.high, 4500); // 3000 × 1.5
      expect(held.suggested, lessThanOrEqualTo(4500));

      held = guard.hold(low: 100, suggested: 150, high: 200, evidence: range);
      expect(held.clamped, isTrue);
      expect(held.low, 1000); // 2000 × 0.5
    });

    test('a reasonable proposal is left alone', () {
      final held = guard.hold(
        low: 2200,
        suggested: 2600,
        high: 3200,
        evidence: range,
      );
      expect(
        [held.low, held.suggested, held.high, held.clamped],
        [2200, 2600, 3200, false],
      );
    });

    test('a collapsed range takes the evidence spread', () {
      var held = guard.hold(
        low: 2250,
        suggested: 2250,
        high: 2250,
        evidence: range,
      );
      expect(
        [held.low, held.suggested, held.high, held.clamped],
        [2000, 2250, 3000, false],
      );

      held = guard.hold(
        low: 3500,
        suggested: 3500,
        high: 3500,
        evidence: range,
      );
      expect([held.low, held.suggested, held.high], [2000, 3500, 3500]);
    });

    test('without enough agreed fares there is no band to hold it in', () {
      const thin = FareRange(
        low: 2000,
        typical: 2500,
        high: 3000,
        agreedCount: 2,
        askedCount: 9,
      );
      final held = guard.hold(
        low: 20000,
        suggested: 25000,
        high: 30000,
        evidence: thin,
      );
      expect(held.clamped, isFalse);
    });
  });

  group('the evidence', () {
    test('is jobs sharing a tag, agreed first, then nearest', () {
      final evidence = FareEvidence.gather(
        [
          job('asked-near', starting: 9000),
          job('agreed-far', agreed: 2500, lat: 34.5),
          job('agreed-near', agreed: 2000),
          job('painting', tags: {JobTag.painting}, agreed: 15000),
          job('no-fare'),
        ],
        tags: {JobTag.plumbing},
        near: here,
        now: now,
      );

      expect(evidence.map((e) => e.title), [
        'Job agreed-near',
        'Job agreed-far',
        'Job asked-near',
      ]);
      expect(evidence.map((e) => e.agreed), [true, true, false]);
    });

    test('an agreement that fell through counts only as what was asked', () {
      final evidence = FareEvidence.gather(
        [
          job(
            'called-off',
            starting: 1800,
            agreed: 2500,
            status: JobStatus.cancelled,
          ),
        ],
        tags: {JobTag.plumbing},
        now: now,
      );
      expect(evidence.single.agreed, isFalse);
      expect(evidence.single.fare, 1800);
    });

    test('never includes the job being edited', () {
      final evidence = FareEvidence.gather(
        [job('me', agreed: 2500), job('other', agreed: 3000)],
        tags: {JobTag.plumbing},
        now: now,
        excludingJobId: 'me',
      );
      expect(evidence.single.fare, 3000);
    });

    test('carries the fare, never the people', () {
      final sent = FareEvidence.gather(
        [job('a', agreed: 2500)],
        tags: {JobTag.plumbing},
        near: here,
        now: now,
      ).single.toJson();
      final text = jsonEncode(sent);
      expect(text, isNot(contains('0300')));
      expect(text, isNot(contains('hirer-')));
      expect(text, isNot(contains('worker')));
    });

    test('the range uses agreed fares where there are any, and says so', () {
      final agreed = FareRange.of(
        FareEvidence.gather(
          [
            job('a', agreed: 1500),
            job('b', agreed: 2000),
            job('c', agreed: 2500),
            job('d', starting: 90000),
          ],
          tags: {JobTag.plumbing},
          now: now,
        ),
      )!;
      expect([agreed.low, agreed.typical, agreed.high], [1750, 2000, 2250]);
      expect(agreed.agreedCount, 3);

      final askedOnly = FareRange.of(
        FareEvidence.gather(
          [job('a', starting: 4000)],
          tags: {JobTag.plumbing},
          now: now,
        ),
      )!;
      expect(askedOnly.agreedCount, 0);
      expect(askedOnly.askedCount, 1);
      expect(askedOnly.toJson()['sample'], 0);

      expect(FareRange.of(const []), isNull);
    });
  });

  group('the advisor', () {
    final evidence = FareEvidence.gather(
      [
        for (final (i, fare) in [2000, 2000, 2500, 3000, 3000, 2500].indexed)
          job('j$i', agreed: fare),
      ],
      tags: {JobTag.plumbing},
      now: now,
    );

    test('suggests the typical fare, inside what similar work went for', () {
      final advice = const FareAdvisor().advise(
        FareQuestion(tags: {JobTag.plumbing}, evidence: evidence),
      )!;
      final range = FareRange.of(evidence)!;

      expect(advice.suggested, range.typical);
      expect(advice.low, range.low);
      expect(advice.high, range.high);
      expect(advice.evidence.agreedCount, 6);
    });

    test('with nothing to compare with it says so rather than guess', () {
      expect(
        const FareAdvisor().advise(
          const FareQuestion(tags: {JobTag.plumbing}, evidence: []),
        ),
        isNull,
      );
    });
  });

  group('on the posting form', () {
    Future<(JobController, Job)> setUpJobs() async {
      final store = await LocalStore.open();
      final jobs = JobController(JobRepository(store, MediaStore(store)));
      await jobs.load();
      final editing = jobs.jobs.firstWhere(
        (j) => j.tags.contains(JobTag.plumbing) && j.isLocal == false,
      );
      return (jobs, editing);
    }

    Future<void> openForm(
      WidgetTester tester,
      JobController jobs,
      Job editing,
    ) async {
      final store = await LocalStore.open();
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        appHarness(
          store: store,
          jobs: jobs,
          child: CreateJobScreen(
            initialLocation: editing.location,
            editing: editing,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('suggests from similar jobs and fills the field on request', (
      tester,
    ) async {
      final (jobs, editing) =
          await tester.runAsync(setUpJobs) ?? (throw StateError('no jobs'));
      await openForm(tester, jobs, editing);

      final expected = FareRange.of(
        FareEvidence.gather(
          jobs.jobs,
          tags: editing.tags,
          now: DateTime.now(),
          excludingJobId: editing.id,
        ),
      )!;

      expect(
        find.text('Worked out on this device from similar jobs.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Suggest a fare'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Suggested starting fare'), findsOneWidget);
      // Never written into the field until asked.
      final fareField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '2,000',
      );
      expect(
        tester.widget<TextField>(fareField).controller!.text,
        editing.startingFare?.toString() ?? '',
      );

      await tester.tap(find.textContaining('Use Rs.'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(fareField).controller!.text,
        '${expected.typical}',
      );
    });

    testWidgets('changing the tags takes an answer to another question away', (
      tester,
    ) async {
      final (jobs, editing) =
          await tester.runAsync(setUpJobs) ?? (throw StateError('no jobs'));
      await openForm(tester, jobs, editing);

      await tester.tap(find.text('Suggest a fare'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Suggested starting fare'), findsOneWidget);

      // Taking a tag off is a change whatever the job started with — adding
      // one is refused once it has three.
      final strings = AppStrings.of(
        tester.element(find.byType(CreateJobScreen)),
      );
      await tester.tap(find.text(editing.tags.first.label(strings)).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Suggested starting fare'), findsNothing);
    });
  });
}
