import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/core/layout.dart';
import 'package:trust_hire/core/tokens.dart';
import 'package:trust_hire/features/jobs/job_details_sheet.dart';
import 'package:trust_hire/features/jobs/job_row.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:trust_hire/features/map/job_map.dart';
import 'package:trust_hire/features/map/job_marker.dart';
import 'package:trust_hire/features/map/map_screen.dart';
import 'package:trust_hire/services/local_store.dart';

import 'support/surface.dart';

/// The same build runs on a handset, a tablet and a desktop browser, and for
/// thirteen sprints it only ever laid out for the first — a bottom navigation
/// bar stranded at the foot of a 1440px window, and job rows stretched into
/// bands of white holding forty characters.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<LocalStore> readyStore() async {
    final store = await LocalStore.open();
    await (SettingsController(store)..load()).markIntroSeen();
    return store;
  }

  group('the breakpoints', () {
    test('name what the app does, not the device', () {
      expect(LayoutSize.fromWidth(390), LayoutSize.compact);
      expect(LayoutSize.fromWidth(599), LayoutSize.compact);
      expect(LayoutSize.fromWidth(600), LayoutSize.medium);
      expect(LayoutSize.fromWidth(1023), LayoutSize.medium);
      expect(LayoutSize.fromWidth(1024), LayoutSize.expanded);
      expect(LayoutSize.fromWidth(1920), LayoutSize.expanded);
    });

    test('a phone in landscape gets the room it has', () {
      // 844x390 — the same handset, turned. It is treated by width, because
      // width is what decides whether a rail fits.
      expect(LayoutSize.fromWidth(844), LayoutSize.medium);
      expect(LayoutSize.fromWidth(844).usesRail, isTrue);
    });

    test('only the widest layout splits', () {
      expect(LayoutSize.compact.isSplit, isFalse);
      expect(LayoutSize.medium.isSplit, isFalse);
      expect(LayoutSize.expanded.isSplit, isTrue);
    });
  });

  group('a rail needs height, not only width', () {
    test('a short wide window keeps the bottom bar', () {
      // A phone held sideways. Five destinations with labels plus the posting
      // action is about 450px of rail; at 380 the last one fell below the fold
      // and nothing said so, so Profile was simply unreachable for anyone who
      // did not think to drag a navigation bar.
      expect(LayoutSize.fromSize(const Size(740, 380)), LayoutSize.compact);
      expect(LayoutSize.fromSize(const Size(1200, 400)), LayoutSize.compact);
    });

    test('and a tall one still gets it', () {
      expect(LayoutSize.fromSize(const Size(740, 900)), LayoutSize.medium);
      expect(LayoutSize.fromSize(const Size(1200, 900)), LayoutSize.expanded);
    });

    test('the boundary is where the rail stops fitting', () {
      expect(
        LayoutSize.fromSize(const Size(800, LayoutSize.railNeedsHeight)),
        LayoutSize.medium,
      );
      expect(
        LayoutSize.fromSize(const Size(800, LayoutSize.railNeedsHeight - 1)),
        LayoutSize.compact,
      );
    });
  });

  group('navigation', () {
    testWidgets('a handset keeps the bottom bar', (tester) async {
      await tester.useCompactSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('a tablet moves it to a rail', (tester) async {
      await tester.useMediumSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('a desktop rail carries labels, a tablet rail does not', (
      tester,
    ) async {
      await tester.useExpandedSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );

      await tester.useMediumSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
    });

    testWidgets('every destination is reachable from the rail', (tester) async {
      await tester.useExpandedSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      await tester.tap(find.text('Jobs'));
      await settle(tester);
      expect(find.text('Find work'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await settle(tester);
      expect(find.text('What brings you here'), findsOneWidget);
    });

    testWidgets('posting stays one tap away on every size', (tester) async {
      for (final size in [
        tester.useCompactSurface,
        tester.useMediumSurface,
        tester.useExpandedSurface,
      ]) {
        await size();
        await tester.pumpWidget(TrustHireApp(store: await readyStore()));
        await settle(tester);

        expect(
          find.byType(FloatingActionButton),
          findsOneWidget,
          reason: 'the primary action vanished at one size',
        );
      }
    });
  });

  group('the split view', () {
    testWidgets('a desktop shows the jobs beside the map', (tester) async {
      await tester.useExpandedSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      // The map is still the surface; the rail answers "what is this pin?"
      // without covering it.
      expect(find.byType(JobMap), findsOneWidget);
      expect(find.text('Work on this map'), findsWidgets);
      expect(find.byType(JobRow), findsWidgets);
    });

    testWidgets('a handset shows the map alone', (tester) async {
      await tester.useCompactSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      expect(find.byType(JobMap), findsOneWidget);
      expect(find.text('Work on this map'), findsNothing);
      expect(find.byType(JobRow), findsNothing);
    });

    testWidgets('selecting in the rail selects on the map', (tester) async {
      await tester.useExpandedSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      final rows = find.byType(JobRow);
      expect(rows, findsWidgets);
      expect(
        tester.widgetList<JobRow>(rows).where((r) => r.isSelected),
        isEmpty,
        reason: 'nothing is selected before a tap',
      );

      await tester.tap(rows.first);
      await settle(tester);

      expect(
        tester
            .widgetList<JobRow>(find.byType(JobRow))
            .where((r) => r.isSelected),
        hasLength(1),
        reason: 'the two halves must agree about which job is being looked at',
      );
    });

    testWidgets('the preview card gives way to the rail', (tester) async {
      // On a handset a tapped pin raises a card because there is nowhere else
      // for it to go. Beside a rail, the same card would cover the map to say
      // what the rail already says.
      await tester.useExpandedSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      await tester.tap(find.byType(JobRow).first);
      await settle(tester);

      expect(find.byType(JobPreviewCard), findsNothing);
    });

    testWidgets('the rail can still reach the details', (tester) async {
      // Browsing must not open a sheet on every click, but a list with no way
      // through to the details would be useless.
      await tester.useExpandedSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      await tester.tap(find.text('Open details').first);
      await settle(tester);

      expect(find.byType(JobDetailsSheet), findsOneWidget);
    });
  });

  group('opening on a country of jobs', () {
    testWidgets('the map opens on nearby work, not on the whole country', (
      tester,
    ) async {
      // The seed spans Karachi to Gilgit. Framing all of it puts every pin at
      // dot size with none of them near anybody, and framing none of it leaves
      // a nearly empty screen — the map has to open on one city's worth.
      await tester.useCompactSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      // Zoom is the readable proof: the whole country needs about 5, one city
      // about 11. Anything below 8 means it zoomed out to fit everything.
      //
      // Read from inside the map — the camera is an inherited value, so it is
      // only reachable from a descendant's context.
      final camera = MapCamera.of(
        tester.element(find.byType(MarkerLayer).first),
      );

      expect(
        camera.zoom,
        greaterThan(8),
        reason: 'zoomed out to ${camera.zoom} — that is the whole country',
      );
    });

    testWidgets('and there are pins on it', (tester) async {
      await tester.useCompactSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      expect(
        find.byType(JobMarker).evaluate().length +
            find.byType(ClusterMarker).evaluate().length,
        greaterThan(1),
        reason: 'an all-but-empty map reads as no work available',
      );
    });
  });

  group('reading width', () {
    testWidgets('job rows stop stretching on a wide window', (tester) async {
      await tester.useExpandedSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      await tester.tap(find.text('Jobs'));
      await settle(tester);

      final rows = find.byType(JobRow);
      expect(rows, findsWidgets);

      final width = tester.getSize(rows.first).width;
      expect(
        width,
        lessThanOrEqualTo(BrandSizing.readableWidth),
        reason: 'a row this wide is a band of white with a sentence in it',
      );
      // And it is not so narrow that the constraint has swallowed the layout.
      expect(width, greaterThan(320));
    });

    testWidgets('a handset still uses the whole screen', (tester) async {
      await tester.useCompactSurface();
      await tester.pumpWidget(TrustHireApp(store: await readyStore()));
      await settle(tester);

      await tester.tap(find.text('Jobs'));
      await settle(tester);

      final row = tester.getSize(find.byType(JobRow).first).width;
      final screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      // Allow for the list's own padding — the point is that nothing was
      // taken away from a screen that had none to spare.
      expect(row, greaterThan(screen - 2 * BrandSizing.spaceMd - 1));
    });
  });
}
