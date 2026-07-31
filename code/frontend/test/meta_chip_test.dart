import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/account_controller.dart';
import 'package:trust_hire/services/local_store.dart';

import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/jobs/job_row.dart';
import 'package:trust_hire/features/map/map_screen.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/widgets/meta_chip.dart';

/// The small facts under a job — when, where, how far, what media.
///
/// **This was two widgets that were nearly the same.** The job row's copy
/// capped its width and ellipsised; the map preview card's copy did neither,
/// because it was written second and the reason for the cap lived only in a
/// comment on the first. A `Wrap` hands its child the whole line and lets it
/// draw past the end, so the second copy was one long label away from painting
/// overflow stripes across the card — and nothing would have caught it, since
/// no test had ever put a long label in a preview card on a narrow phone.
///
/// So these tests are about the cap, and about both call sites having it.
void main() {
  final now = DateTime(2026, 7, 27, 10);

  Job job({String? area, List<String> photos = const []}) => Job(
    id: 'j1',
    location: const JobLocation(latitude: 31.5204, longitude: 74.3587),
    createdAt: now,
    title: 'Fix a leaking tap',
    // Real, and long: a Faisalabad neighbourhood with the city after it. This
    // is the string that overflowed the results rail.
    area: area ?? 'Ghulam Muhammad Abad, Faisalabad',
    scheduledTime: now.add(const Duration(hours: 3)),
    photoPaths: photos,
    radiusMetres: 1500,
  );

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Both widgets ask who is looking, to decide whether to mark a job as the
  /// viewer's own. Nothing here depends on the answer.
  Future<Widget> harness(
    Widget child, {
    Locale locale = const Locale('en'),
  }) async {
    final store = await LocalStore.open();

    return ChangeNotifierProvider(
      create: (_) => AccountController(store)..load(),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        theme: BrandTheme.light,
        home: Scaffold(body: child),
      ),
    );
  }

  /// The narrowest phone the product targets, with the largest text a user can
  /// ask for. Both bugs found this round were at a shape nothing tested.
  Future<void> onASmallPhoneWithLargeText(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('a long label is cut rather than drawn past the edge', (
    tester,
  ) async {
    await onASmallPhoneWithLargeText(tester);
    await tester.pumpWidget(
      await harness(
        const Wrap(
          children: [
            MetaChip(
              icon: Icons.place_outlined,
              label: 'Ghulam Muhammad Abad, Faisalabad, Punjab, Pakistan',
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    // **Compared against the screen, not against `MetaChip.maxWidth`.** The
    // first version of this asserted `width <= MetaChip.maxWidth`, which is
    // true of any number the constant could hold — the test passed with the
    // cap set to infinity. A test whose subject is also its expected value
    // measures nothing.
    expect(
      tester.getSize(find.byType(MetaChip)).width,
      lessThan(320.0),
      reason: 'an uncapped chip takes the whole line, which pushes every other '
          'fact about the job onto a row of its own',
    );

    // Cut, not wrapped: the card has room for one line per fact.
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('the job row uses it, at 320px in Urdu', (tester) async {
    await onASmallPhoneWithLargeText(tester);
    await tester.pumpWidget(
      await harness(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: SingleChildScrollView(
            child: JobRow(
              job: job(photos: const ['a.jpg', 'b.jpg']),
              now: now,
              onTap: () {},
            ),
          ),
        ),
        locale: const Locale('ur'),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MetaChip), findsWidgets);
  });

  testWidgets('the map preview card uses it too', (tester) async {
    // The call site that did not have the cap. Same widget, same assertion —
    // that is the point of there being one widget.
    await onASmallPhoneWithLargeText(tester);
    await tester.pumpWidget(
      await harness(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: SingleChildScrollView(
            child: JobPreviewCard(
              job: job(photos: const ['a.jpg', 'b.jpg']),
              viewerLocation: const JobLocation(
                latitude: 24.8607,
                longitude: 67.0011,
              ),
            ),
          ),
        ),
        locale: const Locale('ur'),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    for (final chip in tester.widgetList<MetaChip>(find.byType(MetaChip))) {
      expect(
        tester.getSize(find.byWidget(chip)).width,
        lessThan(320.0),
        reason: 'the preview card is the call site that used to have no cap',
      );
    }
  });
}
