import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/job_controller.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/jobs/job_details_sheet.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';
import 'package:trust_hire/l10n/app_localizations.dart';

/// Sprint 4's definition of done is "CRUD completed". Create is covered in
/// create_job_test; this covers update and delete, including the media those
/// leave behind.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<(JobController, MediaStore, LocalStore)> build() async {
    final store = await LocalStore.open();
    final media = MediaStore(store);
    final controller = JobController(JobRepository(store, media));
    await controller.load();
    return (controller, media, store);
  }

  Job localJob({
    String id = 'local-1',
    String? title = 'My job',
    List<String> photos = const <String>[],
    String? voice,
  }) {
    return Job(
      id: id,
      location: const JobLocation(latitude: 31.52, longitude: 74.36),
      createdAt: DateTime(2026, 7, 20),
      title: title,
      photoPaths: photos,
      voiceNotePath: voice,
      isLocal: true,
    );
  }

  group('update', () {
    test('changes a job in place rather than adding one', () async {
      final (controller, _, _) = await build();
      await controller.saveJob(localJob());
      final before = controller.jobs.length;

      await controller.saveJob(localJob(title: 'Changed'));

      expect(controller.jobs, hasLength(before));
      expect(controller.jobById('local-1')!.title, 'Changed');
    });

    test('survives a reload', () async {
      final (controller, media, store) = await build();
      await controller.saveJob(localJob(title: 'Persisted'));

      final reloaded = JobController(JobRepository(store, media));
      await reloaded.load();

      expect(reloaded.jobById('local-1')!.title, 'Persisted');
    });
  });

  group('delete', () {
    test('removes the job', () async {
      final (controller, _, _) = await build();
      await controller.saveJob(localJob());
      expect(controller.jobById('local-1'), isNotNull);

      await controller.deleteJob('local-1');

      expect(controller.jobById('local-1'), isNull);
    });

    test('takes the job\'s media with it', () async {
      final (controller, media, _) = await build();

      final photo = await media.save(
        Uint8List.fromList([1, 2, 3]),
        extension: 'jpg',
      );
      await controller.saveJob(localJob(photos: [photo]));
      expect(media.read(photo), isNotNull);

      await controller.deleteJob('local-1');

      expect(media.read(photo), isNull);
    });

    test('leaves media still used by another job alone', () async {
      final (controller, media, _) = await build();

      final shared = await media.save(
        Uint8List.fromList([9, 9]),
        extension: 'jpg',
      );
      await controller.saveJob(localJob(id: 'a', photos: [shared]));
      await controller.saveJob(localJob(id: 'b', photos: [shared]));

      await controller.deleteJob('a');

      expect(media.read(shared), isNotNull);
    });
  });

  group('replacing media', () {
    test('dropping a photo prunes its bytes', () async {
      final (controller, media, _) = await build();

      final photo = await media.save(
        Uint8List.fromList([4, 5]),
        extension: 'jpg',
      );
      await controller.saveJob(localJob(photos: [photo]));

      // Save the same job without the photo — an edit that removed it.
      await controller.saveJob(localJob(photos: const []));

      expect(media.read(photo), isNull);
    });

    test('replacing a recording prunes the old one', () async {
      final (controller, media, _) = await build();

      final original = await media.save(
        Uint8List.fromList([1]),
        extension: 'm4a',
      );
      await controller.saveJob(localJob(voice: original));

      final replacement = await media.save(
        Uint8List.fromList([2]),
        extension: 'm4a',
      );
      await controller.saveJob(localJob(voice: replacement));

      expect(media.read(original), isNull);
      expect(media.read(replacement), isNotNull);
    });
  });

  group('the details sheet', () {
    Future<void> openSheet(
      WidgetTester tester,
      JobController controller,
      MediaStore media,
      String jobId,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: controller),
            Provider<MediaStore>.value(value: media),
          ],
          child: MaterialApp(
            localizationsDelegates: AppStrings.localizationsDelegates,
            supportedLocales: AppStrings.supportedLocales,
            theme: BrandTheme.light,
            home: Scaffold(
              body: JobDetailsSheet(jobId: jobId, mediaStore: media),
            ),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> scrollToBottom(WidgetTester tester) async {
      for (var attempt = 0; attempt < 4; attempt++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    testWidgets('offers edit and delete for jobs on this device',
        (tester) async {
      final (controller, media, _) = await build();
      await controller.saveJob(localJob());

      await openSheet(tester, controller, media, 'local-1');
      await scrollToBottom(tester);

      expect(find.text('Edit Job'), findsOneWidget);
      expect(find.text('Delete Job'), findsOneWidget);
    });

    testWidgets('offers neither for seeded jobs', (tester) async {
      final (controller, media, _) = await build();

      await openSheet(tester, controller, media, 'seed-001');
      await scrollToBottom(tester);

      expect(find.text('Edit Job'), findsNothing);
      expect(find.text('Delete Job'), findsNothing);
    });

    testWidgets('deleting asks first, and can be declined', (tester) async {
      final (controller, media, _) = await build();
      await controller.saveJob(localJob());

      await openSheet(tester, controller, media, 'local-1');
      await scrollToBottom(tester);

      await tester.tap(find.text('Delete Job'));
      await tester.pumpAndSettle();

      // Section 22 — the destructive choice is named, never "Yes".
      expect(find.text('Delete this job?'), findsOneWidget);
      expect(find.text('Keep Job'), findsOneWidget);

      await tester.tap(find.text('Keep Job'));
      await tester.pumpAndSettle();

      expect(controller.jobById('local-1'), isNotNull);
    });
  });
}
