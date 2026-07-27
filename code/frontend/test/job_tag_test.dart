import 'package:flutter/material.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/features/jobs/job_filter.dart';
import 'package:trust_hire/features/jobs/job_filter_controller.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

import 'support/test_strings.dart';

/// Tags replaced the POC's optional job type in P1-1. A hirer now picks one to
/// three, and that choice is what decides who ever sees the job — so these
/// tests hold the vocabulary, the icon fallbacks and the migration of jobs
/// written before tags existed.
void main() {
  late AppStrings strings;

  setUpAll(() async => strings = await loadStrings());

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  final now = DateTime(2026, 7, 27, 10);

  Job job({
    Set<JobTag> tags = const <JobTag>{},
    String? title,
    String? voice,
    List<String> photos = const <String>[],
  }) {
    return Job(
      id: 'j1',
      location: const JobLocation(latitude: 33.6844, longitude: 73.0479),
      createdAt: now,
      tags: tags,
      title: title,
      voiceNotePath: voice,
      photoPaths: photos,
    );
  }

  group('the vocabulary', () {
    test('every tag has a label in the active language', () {
      for (final tag in JobTag.values) {
        expect(tag.label(strings), isNotEmpty, reason: 'unlabelled: ${tag.id}');
      }
    });

    test('ids survive a round trip', () {
      for (final tag in JobTag.values) {
        expect(JobTag.fromId(tag.id), tag);
      }
    });

    test('an unknown id reads as unset rather than throwing', () {
      // Data from a newer version of the app. Losing one tag is recoverable;
      // failing to load the job is not.
      expect(JobTag.fromId('quantum_plumbing'), isNull);
      expect(JobTag.fromId(null), isNull);
    });

    test('the default worker tag is a real, postable tag', () {
      // Workers default to it, so a hirer who does not know which trade they
      // need must be able to reach them.
      expect(JobTag.defaultWorkerTags, isNotEmpty);
      expect(JobTag.values, containsAll(JobTag.defaultWorkerTags));
    });
  });

  group('tags as content', () {
    test('a tag alone is enough to post', () {
      // Picking "Plumbing" says what the work is, which is content.
      expect(job(tags: {JobTag.plumbing}).hasContent, isTrue);
    });

    test('a job from before tags existed still loads', () {
      // The model tolerates an empty set even though the form no longer
      // produces one — refusing to load would lose a user's own work.
      final legacy = job(title: 'Fix the gate');

      expect(legacy.tags, isEmpty);
      expect(legacy.hasContent, isTrue);
    });
  });

  group('the icon', () {
    test('comes from the tag when one was chosen', () {
      expect(job(tags: {JobTag.driving}).icon, JobTag.driving.icon);
    });

    test('falls back to what the job carries when there is no tag', () {
      expect(job(voice: 'v.wav').icon, Icons.mic);
      expect(job(photos: const ['p.png']).icon, Icons.photo_camera);
      expect(job().icon, Icons.work);
    });

    test('a chosen tag wins over the media the job carries', () {
      // Otherwise every voice-note job looks identical on the map, which is
      // the whole reason for having tags.
      final tagged = job(tags: {JobTag.painting}, voice: 'v.wav');
      expect(tagged.icon, JobTag.painting.icon);
      expect(tagged.icon, isNot(Icons.mic));
    });

    test('several tags lead with the first', () {
      final multi = job(tags: {JobTag.masonry, JobTag.construction});
      expect(multi.primaryTag, JobTag.masonry);
      expect(multi.icon, JobTag.masonry.icon);
    });
  });

  group('the heading', () {
    test('uses the tag when there is no title or description', () {
      expect(job(tags: {JobTag.carpentry}).displayTitle(strings), 'Carpentry');
    });

    test('does not use the vague tag as a heading', () {
      // "General work" says nothing, so the media wording is better.
      expect(
        job(tags: {JobTag.misc}, voice: 'v.wav').displayTitle(strings),
        'Voice note job',
      );
    });

    test('a real title still wins', () {
      expect(
        job(
          tags: {JobTag.plumbing},
          title: 'Tap dripping',
        ).displayTitle(strings),
        'Tap dripping',
      );
    });
  });

  group('storage', () {
    test('round-trips through JSON', () {
      final restored = Job.fromJson(
        job(tags: {JobTag.tutoring, JobTag.misc}).toJson(),
      );
      expect(restored.tags, {JobTag.tutoring, JobTag.misc});
    });

    test('a job saved before tags existed reads its single type', () {
      // The POC wrote `type: "plumbing"`. Jobs already in local storage must
      // come back as a one-tag job, not an untagged one that nobody sees.
      final legacy = job(tags: {JobTag.plumbing}).toJson()
        ..remove('tags')
        ..['type'] = 'plumbing';

      expect(Job.fromJson(legacy).tags, {JobTag.plumbing});
    });

    test('an unknown tag from newer data is dropped, not fatal', () {
      final json = job(tags: {JobTag.plumbing}).toJson()
        ..['tags'] = ['plumbing', 'quantum_plumbing'];

      expect(Job.fromJson(json).tags, {JobTag.plumbing});
    });

    test('copyWith replaces the whole set', () {
      final tagged = job(tags: {JobTag.cleaning});
      expect(tagged.copyWith(tags: {JobTag.cooking}).tags, {JobTag.cooking});
      expect(tagged.copyWith().tags, {JobTag.cleaning});
    });

    test('geofence settings survive a round trip', () {
      final wide = Job(
        id: 'g',
        location: const JobLocation(latitude: 33.68, longitude: 73.04),
        createdAt: now,
        tags: const {JobTag.legal},
        geofenceMetres: 4000,
        openToAllLocations: true,
      );

      final restored = Job.fromJson(wide.toJson());
      expect(restored.geofenceMetres, 4000);
      expect(restored.openToAllLocations, isTrue);
    });
  });

  group('filtering', () {
    final plumbing = Job(
      id: 'a',
      location: const JobLocation(latitude: 33.68, longitude: 73.04),
      createdAt: now,
      tags: const {JobTag.plumbing},
    );
    final driving = Job(
      id: 'b',
      location: const JobLocation(latitude: 33.68, longitude: 73.04),
      createdAt: now,
      tags: const {JobTag.driving},
    );
    final untagged = Job(
      id: 'c',
      location: const JobLocation(latitude: 33.68, longitude: 73.04),
      createdAt: now,
      title: 'Something',
    );
    final all = [plumbing, driving, untagged];

    test('an empty tag filter keeps everything', () {
      expect(
        const JobFilter().apply(all, now: now, strings: strings),
        hasLength(3),
      );
    });

    test('keeps only the chosen kinds', () {
      final filter = JobFilter(tags: {JobTag.plumbing});
      expect(filter.apply(all, now: now, strings: strings).map((j) => j.id), [
        'a',
      ]);
    });

    test('several kinds widen the result', () {
      final filter = JobFilter(tags: {JobTag.plumbing, JobTag.driving});
      expect(filter.apply(all, now: now, strings: strings), hasLength(2));
    });

    test('one matching tag out of several is enough', () {
      final mixed = Job(
        id: 'd',
        location: const JobLocation(latitude: 33.68, longitude: 73.04),
        createdAt: now,
        tags: const {JobTag.masonry, JobTag.construction},
      );
      final filter = JobFilter(tags: {JobTag.construction});

      expect(
        filter
            .apply([...all, mixed], now: now, strings: strings)
            .map((j) => j.id),
        ['d'],
      );
    });

    test('does hide untagged jobs, unlike the time filter', () {
      // Deliberate and different from the time filter: asking for a kind is a
      // question a job that never said its kind cannot answer.
      final filter = JobFilter(tags: {JobTag.plumbing});
      expect(
        filter.apply(all, now: now, strings: strings).map((j) => j.id),
        isNot(contains('c')),
      );
    });

    test('search finds a job by its tag label', () {
      const filter = JobFilter(query: 'driving');
      expect(filter.apply(all, now: now, strings: strings).map((j) => j.id), [
        'b',
      ]);
    });

    test('toggling a tag on the controller adds then removes it', () {
      final controller = JobFilterController();

      controller.toggleTag(JobTag.masonry);
      expect(controller.filter.tags, {JobTag.masonry});
      expect(controller.isActive, isTrue);

      controller.toggleTag(JobTag.masonry);
      expect(controller.filter.tags, isEmpty);
      expect(controller.isActive, isFalse);
    });
  });

  group('the seed data', () {
    Future<List<Job>> seededJobs() async {
      final store = await LocalStore.open();
      final repository = JobRepository(store, MediaStore(store));
      await repository.ensureSeeded();
      return repository.fetchJobs();
    }

    test('spans Islamabad, Rawalpindi and Kashmir', () async {
      final jobs = await seededJobs();

      bool near(Job j, double lat, double lng) =>
          (j.location.latitude - lat).abs() < 0.35 &&
          (j.location.longitude - lng).abs() < 0.35;

      expect(
        jobs.any((j) => near(j, 33.6844, 73.0479)),
        isTrue,
        reason: 'expected jobs around Islamabad',
      );
      expect(
        jobs.any((j) => near(j, 33.5651, 73.0169)),
        isTrue,
        reason: 'expected jobs around Rawalpindi',
      );
      expect(
        jobs.any((j) => near(j, 34.3700, 73.4711)),
        isTrue,
        reason: 'expected jobs around Muzaffarabad',
      );
      expect(
        jobs.any((j) => near(j, 33.1478, 73.7519)),
        isTrue,
        reason: 'expected jobs around Mirpur',
      );
    });

    test('every seeded job carries one to three tags', () async {
      // Phase 1 makes tags mandatory, and an untagged job would be invisible
      // to everyone — a demo dataset with holes in it would look like a bug.
      final jobs = await seededJobs();

      expect(jobs, isNotEmpty);
      for (final job in jobs) {
        expect(job.tags, isNotEmpty, reason: '${job.id} has no tags');
        expect(job.tags.length, lessThanOrEqualTo(3), reason: job.id);
      }
    });

    test('includes a specialty job that a general worker cannot see', () async {
      // Keeps the visibility rule visible in the demo rather than only in
      // tests: without one of these, every seeded job reaches every worker.
      final jobs = await seededJobs();
      final specialties = jobs.where(
        (j) => !j.tags.any(JobTag.defaultWorkerTags.contains),
      );

      expect(specialties, isNotEmpty);
    });

    test('includes work that needs no travel', () async {
      final jobs = await seededJobs();
      expect(jobs.where((j) => j.openToAllLocations), isNotEmpty);
    });
  });
}
