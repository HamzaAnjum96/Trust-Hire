import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/features/map/location_controller.dart';
import 'package:trust_hire/features/onboarding/onboarding_screen.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/location_service.dart';

import 'support/test_strings.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService([
    this.result = const LocationResult(
      LocationStatus.available,
      JobLocation(latitude: 33.68, longitude: 73.04),
    ),
  ]);

  final LocationResult result;
  int calls = 0;

  @override
  Future<LocationResult> current() async {
    calls++;
    return result;
  }
}

/// The app used to ask for location the moment it launched, with no
/// explanation — exactly what section 19 warns against. It also gave a
/// forms-averse audience no hint that posting is done by speaking.
void main() {
  late AppStrings strings;

  setUpAll(() async => strings = await loadStrings());

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpIntro(
    WidgetTester tester, {
    required LocationController location,
    VoidCallback? onFinished,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: OnboardingScreen(
          location: location,
          onFinished: onFinished ?? () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('what it says', () {
    testWidgets('leads with the promise, not with a permission', (
      tester,
    ) async {
      final service = _FakeLocationService();
      await pumpIntro(tester, location: LocationController(service));

      expect(find.text(strings.onboardWelcomeTitle), findsOneWidget);
      // Nothing has been asked for yet.
      expect(service.calls, 0);
    });

    testWidgets('explains that posting is done by speaking', (tester) async {
      // The central idea is unusual enough that a forms-averse audience will
      // not find it by poking around.
      await pumpIntro(tester, location: LocationController());

      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();

      expect(find.text(strings.onboardVoiceTitle), findsOneWidget);
    });

    testWidgets('says why location helps, and that refusing is fine', (
      tester,
    ) async {
      await pumpIntro(tester, location: LocationController());

      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();

      expect(find.text(strings.onboardLocationTitle), findsOneWidget);
      expect(find.text(strings.onboardPrivacyNote), findsOneWidget);
      // Refusing is offered as plainly as accepting.
      expect(find.text(strings.onboardAllowLocation), findsOneWidget);
      expect(find.text(strings.onboardNotNow), findsOneWidget);
    });
  });

  group('asking for location', () {
    testWidgets('happens only on the last panel, and only on request', (
      tester,
    ) async {
      final service = _FakeLocationService();
      final location = LocationController(service);
      await pumpIntro(tester, location: location);

      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();

      // Reaching the panel is not consent.
      expect(service.calls, 0);

      await tester.tap(find.text(strings.onboardAllowLocation));
      await tester.pumpAndSettle();

      expect(service.calls, 1);
      expect(location.position, isNotNull);
    });

    testWidgets('declining asks for nothing and still finishes', (
      tester,
    ) async {
      final service = _FakeLocationService();
      var finished = false;

      await pumpIntro(
        tester,
        location: LocationController(service),
        onFinished: () => finished = true,
      );

      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.onboardNotNow));
      await tester.pumpAndSettle();

      expect(service.calls, 0);
      expect(finished, isTrue);
    });

    testWidgets('a refusal at the system prompt still finishes', (
      tester,
    ) async {
      final service = _FakeLocationService(
        const LocationResult(LocationStatus.denied),
      );
      var finished = false;

      await pumpIntro(
        tester,
        location: LocationController(service),
        onFinished: () => finished = true,
      );

      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.onboardNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.onboardAllowLocation));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });
  });

  group('skipping', () {
    testWidgets('is available from the first panel', (tester) async {
      var finished = false;
      await pumpIntro(
        tester,
        location: LocationController(),
        onFinished: () => finished = true,
      );

      await tester.tap(find.text(strings.onboardSkip));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });
  });

  group('the first run', () {
    testWidgets('opens on the intro, not the map', (tester) async {
      final store = await LocalStore.open();

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Nearby work'), findsNothing);
    });

    testWidgets('later runs go straight to the map', (tester) async {
      final store = await LocalStore.open();
      await (SettingsController(store)..load()).markIntroSeen();

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Nearby work'), findsOneWidget);
    });

    testWidgets('finishing the intro reveals the app', (tester) async {
      final store = await LocalStore.open();

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      await tester.tap(find.text(strings.onboardSkip));
      await settle(tester);

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Nearby work'), findsOneWidget);
    });
  });

  group('the intro flag', () {
    test('starts unset and persists once seen', () async {
      final store = await LocalStore.open();
      final settings = SettingsController(store)..load();

      expect(settings.introSeen, isFalse);
      await settings.markIntroSeen();

      expect((SettingsController(store)..load()).introSeen, isTrue);
    });

    test('can be reset, so the intro shows again', () async {
      final store = await LocalStore.open();
      final settings = SettingsController(store)..load();
      await settings.markIntroSeen();

      await settings.resetIntro();

      expect(settings.introSeen, isFalse);
      expect((SettingsController(store)..load()).introSeen, isFalse);
    });
  });
}
