import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/features/jobs/job_filter.dart';
import 'package:trust_hire/features/jobs/job_filter_controller.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_type.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

/// The job type is chosen by the poster and drives the marker icon — but it
/// stays optional, because the brand guidelines want categories inferred
/// rather than demanded. These tests hold both halves of that in place.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  final now = DateTime(2026, 7, 27, 10);

  Job job({
    JobType? type,
    String? title,
    String? voice,
    List<String> photos = const <String>[],
  }) {
    return Job(
      id: 'j1',
      location: const JobLocation(latitude: 33.6844, longitude: 73.0479),
      createdAt: now,
      type: type,
      title: title,
      voiceNotePath: voice,
      photoPaths: photos,
    );
  }

  group('choosing a type is optional', () {
    test('a job with no type is perfectly valid', () {
      final untyped = job(title: 'Fix the gate');

      expect(untyped.type, isNull);
      expect(untyped.hasContent, isTrue);
    });

    test('a type alone is enough to post', () {
      // Picking "Plumbing" says what the work is, which is content.
      expect(job(type: JobType.plumbing).hasContent, isTrue);
    });
  });

  group('the icon', () {
    test('comes from the type when one was chosen', () {
      expect(job(type: JobType.driving).icon, JobType.driving.icon);
    });

    test('falls back to what the job carries when it was not', () {
      expect(job(voice: 'v.wav').icon, Icons.mic);
      expect(job(photos: const ['p.png']).icon, Icons.photo_camera);
      expect(job().icon, Icons.work);
    });

    test('a chosen type wins over the media the job carries', () {
      // Otherwise every voice-note job looks identical on the map, which is
      // the whole reason for having types.
      final typed = job(type: JobType.painting, voice: 'v.wav');
      expect(typed.icon, JobType.painting.icon);
      expect(typed.icon, isNot(Icons.mic));
    });
  });

  group('the heading', () {
    test('uses the type when there is no title or description', () {
      expect(job(type: JobType.carpentry).displayTitle, 'Carpentry');
    });

    test('does not use the vague type as a heading', () {
      // "Something else" says nothing, so the media wording is better.
      expect(
        job(type: JobType.other, voice: 'v.wav').displayTitle,
        'Voice note job',
      );
    });

    test('a real title still wins', () {
      expect(
        job(type: JobType.plumbing, title: 'Tap dripping').displayTitle,
        'Tap dripping',
      );
    });
  });

  group('storage', () {
    test('round-trips through JSON', () {
      final restored = Job.fromJson(job(type: JobType.tutoring).toJson());
      expect(restored.type, JobType.tutoring);
    });

    test('an unknown type from newer data loads as unset', () {
      // Better than failing to load the job entirely.
      final json = job(type: JobType.plumbing).toJson()
        ..['type'] = 'quantum_plumbing';

      expect(Job.fromJson(json).type, isNull);
    });

    test('copyWith can clear it', () {
      final typed = job(type: JobType.cleaning);
      expect(typed.copyWith(clearType: true).type, isNull);
      expect(typed.copyWith(type: JobType.cooking).type, JobType.cooking);
      expect(typed.copyWith().type, JobType.cleaning);
    });
  });

  group('filtering', () {
    final plumbing = Job(
      id: 'a',
      location: const JobLocation(latitude: 33.68, longitude: 73.04),
      createdAt: now,
      type: JobType.plumbing,
    );
    final driving = Job(
      id: 'b',
      location: const JobLocation(latitude: 33.68, longitude: 73.04),
      createdAt: now,
      type: JobType.driving,
    );
    final untyped = Job(
      id: 'c',
      location: const JobLocation(latitude: 33.68, longitude: 73.04),
      createdAt: now,
      title: 'Something',
    );
    final all = [plumbing, driving, untyped];

    test('an empty type filter keeps everything', () {
      expect(const JobFilter().apply(all, now: now), hasLength(3));
    });

    test('keeps only the chosen kinds', () {
      final filter = JobFilter(types: {JobType.plumbing});
      expect(filter.apply(all, now: now).map((j) => j.id), ['a']);
    });

    test('several kinds widen the result', () {
      final filter = JobFilter(types: {JobType.plumbing, JobType.driving});
      expect(filter.apply(all, now: now), hasLength(2));
    });

    test('does hide untyped jobs, unlike the time filter', () {
      // Deliberate and different from the time filter: asking for a kind is a
      // question a job that never said its kind cannot answer.
      final filter = JobFilter(types: {JobType.plumbing});
      expect(filter.apply(all, now: now).map((j) => j.id), isNot(contains('c')));
    });

    test('search finds a job by its type label', () {
      const filter = JobFilter(query: 'driving');
      expect(filter.apply(all, now: now).map((j) => j.id), ['b']);
    });

    test('toggling a type on the controller adds then removes it', () {
      final controller = JobFilterController();

      controller.toggleType(JobType.masonry);
      expect(controller.filter.types, {JobType.masonry});
      expect(controller.isActive, isTrue);

      controller.toggleType(JobType.masonry);
      expect(controller.filter.types, isEmpty);
      expect(controller.isActive, isFalse);
    });
  });

  group('the seed data', () {
    test('spans Islamabad, Rawalpindi and Kashmir', () async {
      final store = await LocalStore.open();
      final repository = JobRepository(store, MediaStore(store));
      await repository.ensureSeeded();
      final jobs = await repository.fetchJobs();

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

    test('keeps some jobs untyped, so the fallback stays exercised', () async {
      final store = await LocalStore.open();
      final repository = JobRepository(store, MediaStore(store));
      await repository.ensureSeeded();
      final jobs = await repository.fetchJobs();

      expect(jobs.where((j) => j.type != null), isNotEmpty);
      expect(
        jobs.where((j) => j.type == null),
        isNotEmpty,
        reason: 'an untyped job should remain, since types are optional',
      );
    });
  });
}
