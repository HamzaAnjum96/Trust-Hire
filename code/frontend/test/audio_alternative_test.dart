import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/features/create_job/job_draft_controller.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/services/capture_service.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

/// WCAG 1.2.1 asks for a text alternative to prerecorded audio. A job
/// described only by voice has none, and it never will: the poster spoke
/// because writing is hard, which is the product's entire premise. Requiring
/// text would shut out the people it exists for.
///
/// So the rule these tests hold is the weaker, honest one — the app *says*
/// when a job is audio-only rather than showing a player and letting someone
/// who cannot hear it work out that they have missed something.
class _FakeCapture implements CaptureService {
  _FakeCapture(this.recording);

  final Uint8List? recording;

  @override
  Future<Uint8List?> takePhoto() async => null;

  @override
  Future<Uint8List?> choosePhoto() async => null;

  @override
  Future<bool> hasMicrophonePermission() async => true;

  @override
  Future<bool> startRecording() async => true;

  @override
  Future<Uint8List?> stopRecording() async => recording;

  @override
  Future<void> cancelRecording() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  final now = DateTime(2026, 7, 27, 10);

  Job job({String? title, String? description, String? voice}) => Job(
    id: 'j1',
    location: const JobLocation(latitude: 33.68, longitude: 73.04),
    createdAt: now,
    tags: const {JobTag.plumbing},
    title: title,
    shortDescription: description,
    voiceNotePath: voice,
  );

  group('recognising an audio-only job', () {
    test('a voice note with no words is audio-only', () {
      expect(job(voice: 'v.wav').isAudioOnly, isTrue);
      expect(job(voice: 'v.wav').hasTextDescription, isFalse);
    });

    test('a title is enough to stop being audio-only', () {
      expect(job(voice: 'v.wav', title: 'Tap dripping').isAudioOnly, isFalse);
    });

    test('a message is enough too', () {
      expect(
        job(
          voice: 'v.wav',
          description: 'Leaking since last night',
        ).isAudioOnly,
        isFalse,
      );
    });

    test('whitespace is not words', () {
      expect(job(voice: 'v.wav', title: '   ').isAudioOnly, isTrue);
    });

    test('a job with no voice note is never audio-only', () {
      // Including a photo-only job: it has no audio to be an alternative to.
      expect(job().isAudioOnly, isFalse);
      expect(job(title: 'Fix the gate').isAudioOnly, isFalse);
    });
  });

  group('the posting form', () {
    Future<JobDraftController> draft({Uint8List? recording}) async {
      final store = await LocalStore.open();
      return JobDraftController(
        mediaStore: MediaStore(store),
        capture: _FakeCapture(recording),
        initialLocation: const JobLocation(latitude: 33.68, longitude: 73.04),
      );
    }

    test('asks for words once a voice note is the only description', () async {
      final controller = await draft(recording: Uint8List.fromList([1, 2]));
      expect(controller.wouldBeAudioOnly, isFalse);

      await controller.startRecording();
      await controller.stopRecording();

      expect(controller.wouldBeAudioOnly, isTrue);
    });

    test('stops asking once there are words', () async {
      final controller = await draft(recording: Uint8List.fromList([1, 2]));
      await controller.startRecording();
      await controller.stopRecording();

      controller.setDescription('Tap under the sink');
      expect(controller.wouldBeAudioOnly, isFalse);

      controller.setDescription('   ');
      expect(controller.wouldBeAudioOnly, isTrue);

      controller.setTitle('Tap dripping');
      expect(controller.wouldBeAudioOnly, isFalse);
    });

    test('never blocks the save', () async {
      // The whole point. Someone who cannot write must still be able to post,
      // so this is a prompt and never a rule.
      final controller = await draft(recording: Uint8List.fromList([1, 2]));
      controller.toggleTag(JobTag.plumbing);
      await controller.startRecording();
      await controller.stopRecording();

      expect(controller.wouldBeAudioOnly, isTrue);
      expect(controller.canSave, isTrue);
      expect(controller.problem, isNull);
      expect((await controller.build())!.isAudioOnly, isTrue);
    });
  });
}
