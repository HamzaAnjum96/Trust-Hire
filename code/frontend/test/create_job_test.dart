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

/// A capture service that never touches a camera or microphone.
class _FakeCapture implements CaptureService {
  _FakeCapture({this.photo, this.recording, this.microphoneAvailable = true});

  Uint8List? photo;
  Uint8List? recording;
  bool microphoneAvailable;

  bool isRecording = false;
  int cancelCount = 0;

  @override
  Future<Uint8List?> takePhoto() async => photo;

  @override
  Future<Uint8List?> choosePhoto() async => photo;

  @override
  Future<bool> hasMicrophonePermission() async => microphoneAvailable;

  @override
  Future<bool> startRecording() async {
    if (!microphoneAvailable) return false;
    isRecording = true;
    return true;
  }

  @override
  Future<Uint8List?> stopRecording() async {
    isRecording = false;
    return recording;
  }

  @override
  Future<void> cancelRecording() async {
    isRecording = false;
    cancelCount++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const somewhere = JobLocation(latitude: 31.5204, longitude: 74.3587);

  Future<(JobDraftController, MediaStore, _FakeCapture)> buildDraft({
    Job? editing,
    _FakeCapture? capture,
  }) async {
    final store = await LocalStore.open();
    final media = MediaStore(store);
    final fake = capture ?? _FakeCapture();

    return (
      JobDraftController(
        mediaStore: media,
        capture: fake,
        initialLocation: somewhere,
        editing: editing,
      ),
      media,
      fake,
    );
  }

  group('flexible posting', () {
    test('an empty draft cannot be saved, and says why', () async {
      final (draft, _, _) = await buildDraft();

      expect(draft.hasContent, isFalse);
      // Two things are wrong; the tag is named first because it is the one
      // the form asks for first.
      expect(draft.problem, DraftProblem.noTags);
      expect(draft.canSave, isFalse);

      expect(await draft.build(), isNull);
      expect(draft.saveFailed, isFalse, reason: 'refused, not failed');
    });

    test('a tag alone is still not enough to post', () async {
      // Tags say what kind of work it is; they do not say what the work is.
      final (draft, _, _) = await buildDraft();
      draft.toggleTag(JobTag.plumbing);

      expect(draft.problem, DraftProblem.nothingToShow);
      expect(draft.canSave, isFalse);

      expect(await draft.build(), isNull);
      expect(draft.saveFailed, isFalse, reason: 'refused, not failed');
    });

    test('a title alone is enough, once tagged', () async {
      final (draft, _, _) = await buildDraft();
      draft.toggleTag(JobTag.carpentry);
      draft.setTitle('Fix the gate');

      expect(draft.canSave, isTrue);
      final job = await draft.build();
      expect(job?.title, 'Fix the gate');
    });

    test('a photo alone is enough, once tagged', () async {
      final capture = _FakeCapture(photo: Uint8List.fromList([1, 2, 3]));
      final (draft, media, _) = await buildDraft(capture: capture);
      draft.toggleTag(JobTag.painting);

      await draft.takePhoto();
      expect(draft.canSave, isTrue);

      final job = await draft.build();
      expect(job!.photoPaths, hasLength(1));
      expect(media.read(job.photoPaths.first), capture.photo);
    });

    test('a voice note alone is enough, once tagged', () async {
      final capture = _FakeCapture(recording: Uint8List.fromList([4, 5, 6]));
      final (draft, media, _) = await buildDraft(capture: capture);
      draft.toggleTag(JobTag.plumbing);

      await draft.startRecording();
      expect(draft.isRecording, isTrue);
      // Saving is blocked mid-recording, or the note would be lost.
      expect(draft.canSave, isFalse);

      await draft.stopRecording();
      expect(draft.hasVoiceNote, isTrue);
      expect(draft.canSave, isTrue);

      final job = await draft.build();
      expect(job!.voiceNotePath, isNotNull);
      expect(media.read(job.voiceNotePath!), capture.recording);
    });

    test('whitespace alone is not content', () async {
      final (draft, _, _) = await buildDraft();
      draft.toggleTag(JobTag.cleaning);
      draft.setTitle('   ');
      draft.setDescription('  ');

      expect(draft.hasContent, isFalse);
      expect(draft.canSave, isFalse);
    });
  });

  group('tags', () {
    test(
      'a draft starts with none, so the choice is always deliberate',
      () async {
        final (draft, _, _) = await buildDraft();

        expect(draft.tags, isEmpty);
        expect(draft.problem, DraftProblem.noTags);
      },
    );

    test('toggling adds then removes', () async {
      final (draft, _, _) = await buildDraft();

      draft.toggleTag(JobTag.plumbing);
      expect(draft.tags, {JobTag.plumbing});

      draft.toggleTag(JobTag.plumbing);
      expect(draft.tags, isEmpty);
    });

    test(
      'three is the limit, and the fourth is refused, not swapped',
      () async {
        // Silently evicting the first choice would leave the user unable to
        // tell which three survived.
        final (draft, _, _) = await buildDraft();

        draft.toggleTag(JobTag.plumbing);
        draft.toggleTag(JobTag.electrical);
        draft.toggleTag(JobTag.carpentry);
        expect(draft.canAddTag, isFalse);

        draft.toggleTag(JobTag.driving);

        expect(draft.tags, {
          JobTag.plumbing,
          JobTag.electrical,
          JobTag.carpentry,
        });
        expect(draft.tags, hasLength(JobDraftController.maxTags));
      },
    );

    test('a full draft can still drop one to make room', () async {
      final (draft, _, _) = await buildDraft();

      draft.toggleTag(JobTag.plumbing);
      draft.toggleTag(JobTag.electrical);
      draft.toggleTag(JobTag.carpentry);

      draft.toggleTag(JobTag.carpentry);
      draft.toggleTag(JobTag.driving);

      expect(draft.tags, {JobTag.plumbing, JobTag.electrical, JobTag.driving});
    });

    test('the chosen tags reach the saved job', () async {
      final (draft, _, _) = await buildDraft();
      draft.toggleTag(JobTag.masonry);
      draft.toggleTag(JobTag.construction);
      draft.setTitle('Boundary wall');

      final job = await draft.build();
      expect(job!.tags, {JobTag.masonry, JobTag.construction});
    });
  });

  group('capture failures', () {
    test('a refused microphone is explained, not thrown', () async {
      final capture = _FakeCapture(microphoneAvailable: false);
      final (draft, _, _) = await buildDraft(capture: capture);

      await draft.startRecording();

      expect(draft.isRecording, isFalse);
      expect(draft.microphoneUnavailable, isTrue);
      // The rest of the form still works.
      draft.toggleTag(JobTag.plumbing);
      draft.setTitle('Fix the gate');
      expect(draft.canSave, isTrue);
    });

    test('backing out of the camera adds nothing', () async {
      final (draft, _, _) = await buildDraft(capture: _FakeCapture());

      await draft.takePhoto();

      expect(draft.photos, isEmpty);
      expect(draft.hasContent, isFalse);
    });

    test('discarding a recording keeps the draft clean', () async {
      final capture = _FakeCapture(recording: Uint8List.fromList([7]));
      final (draft, _, _) = await buildDraft(capture: capture);

      await draft.startRecording();
      await draft.cancelRecording();

      expect(draft.isRecording, isFalse);
      expect(draft.hasVoiceNote, isFalse);
      expect(capture.cancelCount, 1);
    });
  });

  group('the job that comes out', () {
    test('is marked as living on this device', () async {
      final (draft, _, _) = await buildDraft();
      draft.toggleTag(JobTag.misc);
      draft.setTitle('Fix the gate');

      final job = await draft.build();
      expect(job!.isLocal, isTrue);
    });

    test('keeps optional fields null rather than empty', () async {
      final (draft, _, _) = await buildDraft();
      draft.toggleTag(JobTag.misc);
      draft.setTitle('Fix the gate');
      draft.setDescription('   ');

      final job = await draft.build();
      expect(job!.shortDescription, isNull);
      expect(job.scheduledTime, isNull);
    });

    test('carries the chosen area and time', () async {
      final (draft, _, _) = await buildDraft();
      draft.toggleTag(JobTag.misc);
      draft.setTitle('Fix the gate');
      draft.setRadius(2500);
      draft.setLocation(const JobLocation(latitude: 31.60, longitude: 74.40));
      final when = DateTime(2026, 8, 1, 9);
      draft.setScheduledTime(when);

      final job = await draft.build();
      expect(job!.radiusMetres, 2500);
      expect(job.location.latitude, 31.60);
      expect(job.scheduledTime, when);
    });

    test('gives every new job its own id', () async {
      final (first, _, _) = await buildDraft();
      first.toggleTag(JobTag.misc);
      first.setTitle('One');
      final (second, _, _) = await buildDraft();
      second.toggleTag(JobTag.misc);
      second.setTitle('Two');

      final a = await first.build();
      final b = await second.build();

      expect(a!.id, isNot(b!.id));
    });
  });

  group('editing an existing job', () {
    Job existing({Set<JobTag> tags = const {JobTag.plumbing}}) => Job(
      id: 'job-1',
      location: somewhere,
      createdAt: DateTime(2026, 7, 1),
      title: 'Original title',
      tags: tags,
      radiusMetres: 800,
      shortDescription: 'Original message',
      photoPaths: const ['assets/images/jobs/plumbing-01.png'],
    );

    test('starts from the job as it stands', () async {
      final (draft, _, _) = await buildDraft(editing: existing());

      expect(draft.isEditing, isTrue);
      expect(draft.title, 'Original title');
      expect(draft.description, 'Original message');
      expect(draft.tags, {JobTag.plumbing});
      expect(draft.radiusMetres, 800);
      expect(draft.photos, hasLength(1));
      expect(draft.photos.first.isNew, isFalse);
    });

    test(
      'a job from before tags asks for one before it can be saved',
      () async {
        // The job is already invisible to every worker. Asking for one tap on
        // the way past is the fix, not an obstacle — and the save bar says so
        // rather than leaving a dead button.
        final (draft, _, _) = await buildDraft(
          editing: existing(tags: const {}),
        );

        expect(draft.problem, DraftProblem.noTags);
        expect(draft.canSave, isFalse);

        draft.toggleTag(JobTag.plumbing);

        expect(draft.canSave, isTrue);
        expect((await draft.build())!.tags, {JobTag.plumbing});
      },
    );

    test('keeps the id and the original posting time', () async {
      final original = existing();
      final (draft, _, _) = await buildDraft(editing: original);
      draft.setTitle('Changed title');

      final job = await draft.build();
      expect(job!.id, original.id);
      expect(job.createdAt, original.createdAt);
      expect(job.title, 'Changed title');
    });

    test('keeps photos it did not touch', () async {
      final (draft, _, _) = await buildDraft(editing: existing());

      final job = await draft.build();
      expect(job!.photoPaths, existing().photoPaths);
    });

    test('can drop a photo', () async {
      final (draft, _, _) = await buildDraft(editing: existing());
      draft.removePhotoAt(0);

      // Still has a title, so it remains postable.
      final job = await draft.build();
      expect(job!.photoPaths, isEmpty);
    });
  });
}
