import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/features/jobs/job_filter.dart';
import 'package:trust_hire/features/jobs/job_filter_controller.dart';
import 'package:trust_hire/models/job.dart';

import 'support/test_strings.dart';

/// Sprint 5's definition of done is "jobs easily discoverable". The subtle
/// part is what filtering must *not* hide: a job with no scheduled time is
/// normal here, not missing data, so a time filter should not bury it.
void main() {
  late AppStrings strings;

  setUpAll(() async => strings = await loadStrings());

  final now = DateTime(2026, 7, 27, 10);
  const here = JobLocation(latitude: 31.5204, longitude: 74.3587);

  Job job(
    String id, {
    String? title,
    String? description,
    DateTime? scheduled,
    JobLocation location = here,
    String? voice,
    List<String> photos = const <String>[],
  }) {
    return Job(
      id: id,
      location: location,
      createdAt: now,
      title: title,
      shortDescription: description,
      scheduledTime: scheduled,
      voiceNotePath: voice,
      photoPaths: photos,
    );
  }

  final today = job(
    'today',
    title: 'Plumber',
    scheduled: DateTime(2026, 7, 27, 16),
  );
  final tomorrow = job(
    'tomorrow',
    title: 'Painter',
    scheduled: DateTime(2026, 7, 28, 9),
  );
  final nextWeek = job(
    'next-week',
    title: 'Mason',
    scheduled: DateTime(2026, 8, 10, 9),
  );
  final anyTime = job('any-time', title: 'Driver');
  final farAway = job(
    'far',
    title: 'Electrician',
    // Roughly 12 km north.
    location: const JobLocation(latitude: 31.63, longitude: 74.3587),
  );
  final withVoice = job('voice', voice: 'v.wav');
  final withPhoto = job('photo', photos: const ['p.png']);

  final all = [
    today,
    tomorrow,
    nextWeek,
    anyTime,
    farAway,
    withVoice,
    withPhoto,
  ];

  List<String> idsOf(List<Job> jobs) => jobs.map((j) => j.id).toList();

  group('search', () {
    test('matches the title', () {
      const filter = JobFilter(query: 'plumber');
      expect(idsOf(filter.apply(all, now: now, strings: strings)), ['today']);
    });

    test('is case insensitive', () {
      const filter = JobFilter(query: 'PAINTER');
      expect(idsOf(filter.apply(all, now: now, strings: strings)), [
        'tomorrow',
      ]);
    });

    test('matches the description too', () {
      final jobs = [job('a', description: 'Bathroom drain blocked')];
      const filter = JobFilter(query: 'drain');
      expect(filter.apply(jobs, now: now, strings: strings), hasLength(1));
    });

    test('every word must match, so extra words narrow', () {
      final jobs = [
        job('a', title: 'Plumber needed', description: 'urgent'),
        job('b', title: 'Plumber needed', description: 'next month'),
      ];

      expect(
        idsOf(
          const JobFilter(
            query: 'plumber urgent',
          ).apply(jobs, now: now, strings: strings),
        ),
        ['a'],
      );
    });

    test('finds a voice-only job by its fallback heading', () {
      const filter = JobFilter(query: 'voice');
      expect(idsOf(filter.apply(all, now: now, strings: strings)), ['voice']);
    });

    test('an empty query matches everything', () {
      const filter = JobFilter(query: '   ');
      expect(
        filter.apply(all, now: now, strings: strings),
        hasLength(all.length),
      );
    });
  });

  group('time', () {
    test('today keeps today', () {
      const filter = JobFilter(time: TimeFilter.today);
      final ids = idsOf(filter.apply(all, now: now, strings: strings));

      expect(ids, contains('today'));
      expect(ids, isNot(contains('tomorrow')));
      expect(ids, isNot(contains('next-week')));
    });

    test('does not hide jobs with no time set', () {
      // "Any time" is a normal state in this product — a job someone would do
      // today. Filtering it out would lose real work.
      for (final option in TimeFilter.values) {
        final ids = idsOf(
          JobFilter(time: option).apply(all, now: now, strings: strings),
        );
        expect(
          ids,
          contains('any-time'),
          reason: '${option.label(strings)} should keep untimed jobs',
        );
      }
    });

    test('this week spans the next seven days', () {
      const filter = JobFilter(time: TimeFilter.thisWeek);
      final ids = idsOf(filter.apply(all, now: now, strings: strings));

      expect(ids, contains('today'));
      expect(ids, contains('tomorrow'));
      expect(ids, isNot(contains('next-week')));
    });

    test('tomorrow keeps only tomorrow', () {
      const filter = JobFilter(time: TimeFilter.tomorrow);
      final ids = idsOf(filter.apply(all, now: now, strings: strings));

      expect(ids, contains('tomorrow'));
      expect(ids, isNot(contains('today')));
    });
  });

  group('distance', () {
    test('near me keeps what is close', () {
      const filter = JobFilter(distance: DistanceFilter.nearMe);
      final ids = idsOf(
        filter.apply(all, now: now, strings: strings, from: here),
      );

      expect(ids, contains('today'));
      expect(ids, isNot(contains('far')));
    });

    test('a wider radius reaches further', () {
      const filter = JobFilter(distance: DistanceFilter.withinTen);
      expect(
        idsOf(filter.apply(all, now: now, strings: strings, from: here)),
        isNot(contains('far')),
      );

      // 12 km away is outside ten but the filter is off entirely without a
      // position.
      expect(
        idsOf(filter.apply(all, now: now, strings: strings)),
        contains('far'),
      );
    });

    test('stands down when there is no position to measure from', () {
      // Emptying the list because location was refused would punish the user
      // for a permission choice.
      const filter = JobFilter(distance: DistanceFilter.nearMe);
      expect(
        filter.apply(all, now: now, strings: strings),
        hasLength(all.length),
      );
    });
  });

  group('media', () {
    test('voice note keeps only jobs that have one', () {
      const filter = JobFilter(withVoiceNote: true);
      expect(idsOf(filter.apply(all, now: now, strings: strings)), ['voice']);
    });

    test('photos keeps only jobs that have them', () {
      const filter = JobFilter(withPhotos: true);
      expect(idsOf(filter.apply(all, now: now, strings: strings)), ['photo']);
    });
  });

  group('combining', () {
    test('filters narrow together', () {
      const filter = JobFilter(
        query: 'plumber',
        time: TimeFilter.today,
        distance: DistanceFilter.nearMe,
      );

      expect(idsOf(filter.apply(all, now: now, strings: strings, from: here)), [
        'today',
      ]);
    });

    test('counts what is active', () {
      const filter = JobFilter(query: 'x', time: TimeFilter.today);
      expect(filter.activeCount, 2);
      expect(filter.isActive, isTrue);
      expect(const JobFilter().isActive, isFalse);
    });
  });

  group('controller', () {
    test('quick filters toggle off when tapped again', () {
      final controller = JobFilterController();

      controller.toggleToday();
      expect(controller.filter.time, TimeFilter.today);
      controller.toggleToday();
      expect(controller.filter.time, TimeFilter.any);

      controller.toggleNearMe();
      expect(controller.filter.distance, DistanceFilter.nearMe);
      controller.toggleNearMe();
      expect(controller.filter.distance, DistanceFilter.any);
    });

    test('clear resets everything', () {
      final controller = JobFilterController()
        ..setQuery('plumber')
        ..setTime(TimeFilter.today)
        ..setWithPhotos(true);

      expect(controller.isActive, isTrue);
      controller.clear();

      expect(controller.isActive, isFalse);
      expect(controller.filter.query, '');
    });

    test('notifies once per real change', () {
      final controller = JobFilterController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setTime(TimeFilter.today);
      // Setting the same value again is not a change.
      controller.setTime(TimeFilter.today);

      expect(notifications, 1);
    });
  });
}
