import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/features/map/job_map.dart';
import 'package:trust_hire/services/local_store.dart';

import 'support/seed_facts.dart';

/// Sprint 0's definition of done is "application launches". This asserts it
/// end to end: the app boots, seeds local storage from the bundled JSON, and
/// renders the navigation scaffold with real job data behind it.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // rootBundle caches the Future for each asset. Across tests that
    // Future belongs to a previous test's async zone and never
    // completes again, so clear the cache between tests.
    rootBundle.clear();
  });

  /// The map's tile layer keeps requests in flight against a tile server the
  /// test cannot reach, so `pumpAndSettle` would never return here. Pumping a
  /// fixed span is enough for the app to load and lay out.
  ///
  /// Map behaviour itself is covered in `map_test.dart`, which injects an
  /// offline tile provider and can settle normally.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('app launches and seeds jobs into local storage', (tester) async {
    final store = await LocalStore.open();
    // The intro is covered in onboarding_test; these assert the
    // shell that follows it.
    await (SettingsController(store)..load()).markIntroSeen();

    await tester.pumpWidget(TrustHireApp(store: store));
    await settle(tester);

    // Navigation scaffold is present with all three destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Primary action is reachable from the landing screen.
    expect(find.text('Post a Job'), findsOneWidget);

    // The map is the landing surface.
    expect(find.text('Nearby work'), findsOneWidget);

    // The seed data made it into local storage.
    final stored = store.readCollection(StoreKeys.jobs);
    expect(stored, isNotNull);
    expect(stored!.length, await SeedFacts.jobCount());
    expect(store.readFlag(StoreKeys.seeded), isTrue);
  });

  testWidgets('every navigation destination opens', (tester) async {
    final store = await LocalStore.open();
    // The intro is covered in onboarding_test; these assert the
    // shell that follows it.
    await (SettingsController(store)..load()).markIntroSeen();

    await tester.pumpWidget(TrustHireApp(store: store));
    await settle(tester);

    await tester.tap(find.text('Jobs'));
    await settle(tester);
    expect(find.text('Find work'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('posting a job is reachable from the shell', (tester) async {
    final store = await LocalStore.open();
    // The intro is covered in onboarding_test; these assert the
    // shell that follows it.
    await (SettingsController(store)..load()).markIntroSeen();

    await tester.pumpWidget(TrustHireApp(store: store));
    await settle(tester);

    await tester.tap(find.text('Post a Job'));
    await settle(tester);

    expect(find.text('Post a job'), findsOneWidget);
  });

  testWidgets('the map still works without a device location', (tester) async {
    final store = await LocalStore.open();
    // The intro is covered in onboarding_test; these assert the
    // shell that follows it.
    await (SettingsController(store)..load()).markIntroSeen();

    // geolocator has no platform implementation under test, so no position is
    // ever produced — the same situation as a refusal.
    await tester.pumpWidget(TrustHireApp(store: store));
    await settle(tester);

    // The map rendered anyway, centred on the fallback.
    expect(find.text('Nearby work'), findsOneWidget);
    expect(find.text('${await SeedFacts.jobCount()} jobs'), findsOneWidget);
  });

  testWidgets('the map fills the screen', (tester) async {
    final store = await LocalStore.open();
    // The intro is covered in onboarding_test; these assert the
    // shell that follows it.
    await (SettingsController(store)..load()).markIntroSeen();

    await tester.pumpWidget(TrustHireApp(store: store));
    await settle(tester);

    // Presence is not enough — a Stack of positioned children collapses to
    // zero if nothing forces it to expand, which renders an invisible map
    // that still satisfies a find.text assertion.
    final mapSize = tester.getSize(find.byType(JobMap));
    expect(mapSize.width, greaterThan(300));
    expect(mapSize.height, greaterThan(400));
  });

  // How a refusal is explained is covered deterministically in
  // location_controller_test.dart, against a fake location service.
}
