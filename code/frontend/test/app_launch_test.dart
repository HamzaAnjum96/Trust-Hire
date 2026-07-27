import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/services/local_store.dart';

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

  testWidgets('app launches and seeds jobs into local storage', (tester) async {
    final store = await LocalStore.open();

    await tester.pumpWidget(TrustHireApp(store: store));
    await tester.pumpAndSettle();

    // Navigation scaffold is present with all three destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Primary action is reachable from the landing screen.
    expect(find.text('Post a Job'), findsOneWidget);

    // The seed data made it into local storage.
    final stored = store.readCollection(StoreKeys.jobs);
    expect(stored, isNotNull);
    expect(stored!.length, 12);
    expect(store.readFlag(StoreKeys.seeded), isTrue);
  });

  testWidgets('every navigation destination opens', (tester) async {
    final store = await LocalStore.open();

    await tester.pumpWidget(TrustHireApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(find.text('All jobs'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('posting a job is reachable from the shell', (tester) async {
    final store = await LocalStore.open();

    await tester.pumpWidget(TrustHireApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post a Job'));
    await tester.pumpAndSettle();

    expect(find.text('Post a job'), findsOneWidget);
  });
}
