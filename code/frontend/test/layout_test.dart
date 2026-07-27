import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/core/layout.dart';
import 'package:trust_hire/core/tokens.dart';
import 'package:trust_hire/features/jobs/job_row.dart';
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
