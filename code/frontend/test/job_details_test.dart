import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/job_controller.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/jobs/job_details_sheet.dart';
import 'package:trust_hire/features/jobs/photo_gallery.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';
import 'package:trust_hire/widgets/voice_note_player.dart';

/// Sprint 2's definition of done is "every seeded job opens correctly" — which
/// matters most for the jobs that carry only some of the information, since
/// the product treats missing information as normal.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<(JobController, MediaStore)> buildControllers() async {
    final store = await LocalStore.open();
    final media = MediaStore(store);
    final controller = JobController(JobRepository(store, media));
    await controller.load();
    return (controller, media);
  }

  Future<void> openSheet(
    WidgetTester tester,
    JobController controller,
    MediaStore media,
    String jobId, {
    JobLocation? viewerLocation,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: controller),
          Provider<MediaStore>.value(value: media),
        ],
        child: MaterialApp(
          theme: BrandTheme.light,
          home: Scaffold(
            body: JobDetailsSheet(
              jobId: jobId,
              mediaStore: media,
              viewerLocation: viewerLocation,
            ),
          ),
        ),
      ),
    );
    // The embedded map preview keeps tile requests in flight, so pump a fixed
    // span rather than settling.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The sheet is a ListView, which does not build children below the fold —
  /// so anything further down has to be scrolled into view before asserting.
  Future<void> scrollToBottom(WidgetTester tester) async {
    // Repeated drags rather than one: the list grows as children build, so a
    // single large drag stops short of the real bottom.
    for (var attempt = 0; attempt < 4; attempt++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  testWidgets('every seeded job opens without error', (tester) async {
    final (controller, media) = await buildControllers();

    for (final job in controller.jobs) {
      await openSheet(tester, controller, media, job.id);

      expect(
        find.text(job.displayTitle),
        findsOneWidget,
        reason: 'job ${job.id} should show a heading',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('shows a gallery only for jobs with photos', (tester) async {
    final (controller, media) = await buildControllers();

    // seed-002 has two photos.
    await openSheet(tester, controller, media, 'seed-002');
    expect(find.byType(PhotoGallery), findsOneWidget);

    // seed-003 is a voice note with no photos at all.
    await openSheet(tester, controller, media, 'seed-003');
    expect(find.byType(PhotoGallery), findsNothing);
  });

  testWidgets('shows a player only for jobs with a voice note',
      (tester) async {
    final (controller, media) = await buildControllers();

    await openSheet(tester, controller, media, 'seed-003');
    expect(find.byType(VoiceNotePlayer), findsOneWidget);

    // seed-005 has a photo and a title but no recording.
    await openSheet(tester, controller, media, 'seed-005');
    expect(find.byType(VoiceNotePlayer), findsNothing);
  });

  testWidgets('a job with only a voice note still opens usefully',
      (tester) async {
    final (controller, media) = await buildControllers();

    // seed-008 has no title, no description, no photos.
    await openSheet(tester, controller, media, 'seed-008');

    expect(find.text('Voice note job'), findsOneWidget);
    expect(find.byType(VoiceNotePlayer), findsOneWidget);

    await scrollToBottom(tester);
    expect(find.text('When'), findsOneWidget);
    expect(find.text('Area'), findsOneWidget);
  });

  testWidgets('shows distance only when the viewer location is known',
      (tester) async {
    final (controller, media) = await buildControllers();

    await openSheet(tester, controller, media, 'seed-001');
    await scrollToBottom(tester);
    expect(find.textContaining('away'), findsNothing);

    await openSheet(
      tester,
      controller,
      media,
      'seed-001',
      viewerLocation: const JobLocation(latitude: 31.60, longitude: 74.40),
    );
    await scrollToBottom(tester);
    expect(find.textContaining('away'), findsOneWidget);
  });

  testWidgets('says the location is approximate', (tester) async {
    final (controller, media) = await buildControllers();
    await openSheet(tester, controller, media, 'seed-001');
    await scrollToBottom(tester);

    expect(
      find.text('This is the general area, not an exact address.'),
      findsOneWidget,
    );
  });

  testWidgets('handles a job deleted while its sheet is open',
      (tester) async {
    final (controller, media) = await buildControllers();
    await openSheet(tester, controller, media, 'seed-001');
    expect(find.text('Kitchen tap leaking'), findsOneWidget);

    await controller.deleteJob('seed-001');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('This job is no longer here.'), findsOneWidget);
  });

  group('MediaStore', () {
    test('round-trips bytes through local storage', () async {
      final store = await LocalStore.open();
      final media = MediaStore(store);

      final bytes = Uint8List.fromList(utf8.encode('a photo'));
      final reference = await media.save(bytes, extension: 'png');

      expect(MediaStore.isLocal(reference), isTrue);
      expect(media.read(reference), bytes);
    });

    test('asset references are left alone', () async {
      final store = await LocalStore.open();
      final media = MediaStore(store);

      const asset = 'assets/images/jobs/plumbing-01.png';
      expect(MediaStore.isLocal(asset), isFalse);
      expect(media.read(asset), isNull);
      // audioplayers wants the path relative to assets/.
      expect(MediaStore.assetKeyFor('assets/audio/voice-01.wav'),
          'audio/voice-01.wav');
    });

    test('pruning drops blobs no job references', () async {
      final store = await LocalStore.open();
      final media = MediaStore(store);

      final kept = await media.save(
        Uint8List.fromList([1, 2, 3]),
        extension: 'png',
      );
      final dropped = await media.save(
        Uint8List.fromList([4, 5, 6]),
        extension: 'png',
      );

      await media.pruneExcept({kept});

      expect(media.read(kept), isNotNull);
      expect(media.read(dropped), isNull);
    });

    test('restoring the seed clears locally captured media', () async {
      final store = await LocalStore.open();
      final media = MediaStore(store);
      final repository = JobRepository(store, media);
      await repository.ensureSeeded();

      final reference = await media.save(
        Uint8List.fromList([9, 9, 9]),
        extension: 'png',
      );
      expect(media.read(reference), isNotNull);

      await repository.resetToSeed();
      expect(media.read(reference), isNull);
    });
  });
}
