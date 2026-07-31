import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/core/layout.dart';
import 'package:trust_hire/services/local_store.dart';

/// Every screen, at every shape, in both themes and both languages.
///
/// **This file exists because the suite was green while four things were
/// broken.** A navigation destination was unreachable on a phone held
/// sideways; a notice sat on top of a button; the map attribution was clipped
/// in half; the posting action was an unlabelled icon. None of them failed a
/// test, because every test ran at one of two window sizes in one theme in one
/// language — and the bugs were in between.
///
/// So this is a matrix rather than a scenario. It asserts almost nothing about
/// *what* is on screen: that is every other file's job. It asserts that each
/// combination renders without throwing — which in a debug build means without
/// overflowing — and that every destination can still be reached.
///
/// Kept deliberately cheap per case, because the value is in the number of
/// cases. If this file ever needs to assert something specific, that assertion
/// belongs in the test file for the feature instead.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  /// The map keeps tile requests in flight against a server the test cannot
  /// reach, so `pumpAndSettle` never returns. A fixed span is enough.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Shapes worth caring about, and why each one is here.
  const shapes = <String, Size>{
    // The narrowest phone still sold in the market this is for.
    'a small phone': Size(320, 720),
    'a phone': Size(390, 844),
    // Short enough that the rail does not fit. **The one that was broken.**
    'a phone held sideways': Size(740, 380),
    // A short browser window, which is what a laptop with a dock looks like.
    'a short window': Size(1024, 500),
    'a tablet': Size(900, 700),
    'a desktop browser': Size(1440, 900),
  };

  /// The five destinations, by the icons that never change with the language.
  ///
  /// Two each: the selected destination shows the filled icon and the outlined
  /// one disappears, so looking for only one of them finds four destinations
  /// and concludes the fifth is missing.
  const destinations = <String, (IconData, IconData)>{
    'map': (Icons.map_outlined, Icons.map),
    'jobs': (Icons.work_outline, Icons.work),
    'directory': (Icons.badge_outlined, Icons.badge),
    'activity': (Icons.bookmark_border, Icons.bookmark),
    'profile': (Icons.person_outline, Icons.person),
  };

  Future<void> open(WidgetTester tester, Size size, {
    required Brightness brightness,
    required Locale locale,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = await LocalStore.open();
    final settings = SettingsController(store)..load();
    await settings.markIntroSeen();
    await settings.setLocale(locale);
    await settings.setThemeMode(
      brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    );

    await tester.pumpWidget(TrustHireApp(store: store));
    await settle(tester);
  }

  for (final shape in shapes.entries) {
    for (final theme in const {'light': Brightness.light, 'dark': Brightness.dark}.entries) {
      for (final language in const {'English': 'en', 'Urdu': 'ur'}.entries) {
        testWidgets(
          'every screen renders on ${shape.key}, ${theme.key}, in ${language.key}',
          (tester) async {
            await open(
              tester,
              shape.value,
              brightness: theme.value,
              locale: Locale(language.value),
            );

            for (final destination in destinations.entries) {
              final icon = find.byIcon(destination.value.$1);

              // The selected destination shows its filled icon, so the
              // outlined one is absent — that is the current screen and it is
              // already rendered.
              if (icon.evaluate().isEmpty) continue;

              await tester.tap(icon.first, warnIfMissed: false);
              await settle(tester);

              expect(
                tester.takeException(),
                isNull,
                reason: '${destination.key} threw on ${shape.key} '
                    '(${theme.key}, ${language.key}) — an overflow counts',
              );
            }
          },
        );
      }
    }
  }

  group('every destination can be reached', () {
    for (final shape in shapes.entries) {
      testWidgets('on ${shape.key}', (tester) async {
        // **The bug this is for.** On a phone held sideways the rail needed
        // about 450px for five labelled destinations and had 380. It scrolled,
        // but nothing said so, so Profile was simply unreachable — and the
        // suite was green, because no test had ever been that shape.
        await open(
          tester,
          shape.value,
          brightness: Brightness.light,
          locale: const Locale('en'),
        );

        for (final destination in destinations.entries) {
          expect(
            find.byIcon(destination.value.$1).evaluate().isNotEmpty ||
                find.byIcon(destination.value.$2).evaluate().isNotEmpty,
            isTrue,
            reason: '${destination.key} is not on screen at ${shape.key}; '
                'a destination behind a scroll nobody can see is one nobody '
                'can reach',
          );
        }
      });
    }
  });

  group('the intro is legible before anyone has seen it', () {
    for (final shape in shapes.entries) {
      testWidgets('on ${shape.key}', (tester) async {
        // **The gap this closes.** Every case above marks the intro as seen,
        // so the matrix covered every screen except the first one anybody
        // meets. At 740×380 the panel's 96px medallion and display-sized
        // heading filled the window on their own, and the sentence explaining
        // what Trust Hire *is* sat below a fold with nothing indicating a
        // fold — the same defect as the rail that hid Profile, in the one
        // place where a user has no idea anything is missing.
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = shape.value;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final store = await LocalStore.open();
        await tester.pumpWidget(TrustHireApp(store: store));
        await settle(tester);

        expect(tester.takeException(), isNull);

        // The body of the first slide, whole and on screen. `findsOneWidget`
        // is not enough: a widget scrolled out of view is still found.
        final body = find.textContaining('on a map');
        expect(body, findsOneWidget, reason: 'the intro did not open');

        // **Measured against the panel, not the window.** The first version
        // of this compared the text's bottom to the height of the screen and
        // passed with the fix removed — the sentence was not falling off the
        // display, it was falling out of the scrolling panel, underneath the
        // dots and the Next button that sit below it. Comparing a rect to a
        // box that was never the constraint is the same mistake as comparing
        // a width to the constant that sets it.
        final panel = find
            .ancestor(of: body, matching: find.byType(SingleChildScrollView))
            .first;

        expect(
          tester.getRect(body).bottom,
          lessThanOrEqualTo(tester.getRect(panel).bottom),
          reason: 'the sentence that says what the app is runs past the '
              'bottom of the panel at ${shape.key}, and nothing says to '
              'scroll',
        );
      });
    }
  });

  group('the shape decides the navigation', () {
    test('and a rail is only used where one fits', () {
      for (final shape in shapes.values) {
        final layout = LayoutSize.fromSize(shape);
        if (!layout.usesRail) continue;

        expect(
          shape.height,
          greaterThanOrEqualTo(LayoutSize.railNeedsHeight),
          reason: 'a rail was chosen for a window too short to hold one',
        );
      }
    });
  });
}
