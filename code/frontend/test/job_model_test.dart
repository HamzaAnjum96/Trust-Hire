import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/models/job.dart';

/// The core principle from the sprint plan is that missing information is
/// acceptable — a job posted with voice alone, a photo alone, or a title alone
/// is valid. These tests pin that behaviour down.
void main() {
  final now = DateTime(2026, 7, 27, 10);

  Job job({
    String? title,
    String? description,
    String? voice,
    List<String> photos = const <String>[],
    DateTime? scheduled,
  }) {
    return Job(
      id: 'j1',
      location: const JobLocation(latitude: 31.52, longitude: 74.36),
      createdAt: now,
      title: title,
      shortDescription: description,
      voiceNotePath: voice,
      photoPaths: photos,
      scheduledTime: scheduled,
    );
  }

  group('flexible posting', () {
    test('a voice note alone is enough', () {
      expect(job(voice: 'assets/audio/voice-01.wav').hasContent, isTrue);
    });

    test('a photo alone is enough', () {
      expect(job(photos: const ['a.png']).hasContent, isTrue);
    });

    test('a title alone is enough', () {
      expect(job(title: 'Fix the tap').hasContent, isTrue);
    });

    test('an entirely empty job has no content', () {
      expect(job().hasContent, isFalse);
    });

    test('whitespace does not count as content', () {
      expect(job(title: '   ').hasContent, isFalse);
    });
  });

  group('displayTitle', () {
    test('uses the title when present', () {
      expect(job(title: 'Fix the tap').displayTitle, 'Fix the tap');
    });

    test('falls back to a short description', () {
      expect(job(description: 'Drain blocked').displayTitle, 'Drain blocked');
    });

    test('truncates a long description', () {
      final long = 'A' * 60;
      final title = job(description: long).displayTitle;
      expect(title.length, 40);
      expect(title.endsWith('…'), isTrue);
    });

    test('describes the media when there is no text at all', () {
      expect(job(voice: 'v.wav').displayTitle, 'Voice note job');
      expect(job(photos: const ['a.png']).displayTitle, 'Photo job');
      expect(job().displayTitle, 'Untitled job');
    });
  });

  group('scheduling', () {
    test('isToday matches the same calendar day', () {
      expect(job(scheduled: DateTime(2026, 7, 27, 18)).isToday(now), isTrue);
      expect(job(scheduled: DateTime(2026, 7, 28, 9)).isToday(now), isFalse);
      expect(job().isToday(now), isFalse);
    });
  });

  group('serialisation', () {
    test('round-trips through JSON', () {
      final original = Job(
        id: 'j9',
        location: const JobLocation(latitude: 31.5, longitude: 74.3),
        createdAt: now,
        title: 'Paint two rooms',
        radiusMetres: 1500,
        scheduledTime: DateTime(2026, 7, 29, 9),
        voiceNotePath: 'v.wav',
        voiceNoteDuration: const Duration(seconds: 11),
        photoPaths: const ['a.png', 'b.png'],
        shortDescription: 'Before Eid',
        postedBy: 'user-002',
        isLocal: true,
      );

      final restored = Job.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.radiusMetres, original.radiusMetres);
      expect(restored.scheduledTime, original.scheduledTime);
      expect(restored.voiceNoteDuration, original.voiceNoteDuration);
      expect(restored.photoPaths, original.photoPaths);
      expect(restored.isLocal, isTrue);
      expect(restored.location, original.location);
    });
  });

  group('copyWith', () {
    test('clears fields explicitly rather than by passing null', () {
      final original = job(title: 'Fix the tap', voice: 'v.wav');

      expect(original.copyWith(title: 'New title').title, 'New title');
      expect(original.copyWith(clearTitle: true).title, isNull);
      expect(original.copyWith(clearVoiceNote: true).hasVoiceNote, isFalse);

      // Passing nothing leaves the field alone.
      expect(original.copyWith().title, 'Fix the tap');
    });
  });

  group('distance', () {
    test('haversine gives a sane distance across Lahore', () {
      const gulberg = JobLocation(latitude: 31.5204, longitude: 74.3587);
      const joharTown = JobLocation(latitude: 31.5385, longitude: 74.3502);

      final metres = gulberg.distanceTo(joharTown);
      // Roughly 2.1 km apart.
      expect(metres, greaterThan(1800));
      expect(metres, lessThan(2400));
    });

    test('distance to itself is zero', () {
      const point = JobLocation(latitude: 31.5, longitude: 74.3);
      expect(point.distanceTo(point), closeTo(0, 0.001));
    });
  });
}
