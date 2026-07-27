import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/core/tokens.dart';
import 'package:trust_hire/services/local_store.dart';

/// Section 29 lists accessibility as a requirement, not a polish step. These
/// tests hold the app to the numbers written there rather than to a glance.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('the running app', () {
    testWidgets('meets the tap target, label and contrast guidelines', (
      tester,
    ) async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      // Flutter's own audits: 48x48 targets on Android, 44x44 on iOS, plus
      // text contrast and labelled tappables.
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives the largest text scale without overflowing', (
      tester,
    ) async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();

      await tester.pumpWidget(
        MediaQuery(
          // Someone on a cheap phone in bright sun may well be at 2x.
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: TrustHireApp(store: store),
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: TrustHireApp(store: store),
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with animations disabled', (tester) async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TrustHireApp(store: store),
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('the palette', () {
    /// WCAG relative luminance.
    double luminance(Color colour) {
      double channel(double value) {
        final v = value;
        return v <= 0.03928
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      }

      return 0.2126 * channel(colour.r) +
          0.7152 * channel(colour.g) +
          0.0722 * channel(colour.b);
    }

    double contrast(Color a, Color b) {
      final la = luminance(a);
      final lb = luminance(b);
      final lighter = math.max(la, lb);
      final darker = math.min(la, lb);
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('text pairings the app actually uses clear AA', () {
      final pairs = <String, (Color, Color)>{
        'Ink on Mist': (BrandColours.ink, BrandColours.mist),
        'Ink on Warm Sand': (BrandColours.ink, BrandColours.warmSand),
        'Ink on White': (BrandColours.ink, BrandColours.white),
        'Slate on White': (BrandColours.slate, BrandColours.white),
        'Slate on Mist': (BrandColours.slate, BrandColours.mist),
        'Slate on Warm Sand': (BrandColours.slate, BrandColours.warmSand),
        'White on Trust Burgundy': (
          BrandColours.white,
          BrandColours.trustBurgundy,
        ),
        'White on Deep Burgundy': (
          BrandColours.white,
          BrandColours.deepBurgundy,
        ),
        'Trust Burgundy on White': (
          BrandColours.trustBurgundy,
          BrandColours.white,
        ),
        'Error Red on White': (BrandColours.errorRed, BrandColours.white),
        'Dark text on dark background': (
          BrandColours.darkTextPrimary,
          BrandColours.darkBackground,
        ),
        'Dark secondary text on dark surface': (
          BrandColours.darkTextSecondary,
          BrandColours.darkSurface,
        ),
      };

      pairs.forEach((name, pair) {
        expect(
          contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.5),
          reason: '$name must clear WCAG AA for normal text',
        );
      });
    });

    test('white on copper is not used for small text', () {
      // Section 9 warns against it and the numbers agree: it lands just under
      // 3:1, so copper carries icons and fills, never body copy.
      final ratio = contrast(BrandColours.white, BrandColours.copper);
      expect(ratio, lessThan(4.5));
    });

    test('warning amber is a fill colour, not a text colour', () {
      // 2.65:1 on white. The notice panel therefore carries the tone in its
      // icon and border while the message itself stays in Ink.
      final ratio = contrast(BrandColours.warningAmber, BrandColours.white);
      expect(ratio, lessThan(3.0));
    });
  });

  group('the tokens', () {
    test('touch targets meet the documented minimums', () {
      expect(BrandSizing.touchTargetMinimum, greaterThanOrEqualTo(44));
      expect(BrandSizing.touchTargetPreferred, greaterThanOrEqualTo(48));
    });

    test('no type style is smaller than 12px', () {
      final sizes = <double?>[
        BrandType.display.fontSize,
        BrandType.pageHeading.fontSize,
        BrandType.sectionHeading.fontSize,
        BrandType.body.fontSize,
        BrandType.supporting.fontSize,
        BrandType.caption.fontSize,
        BrandType.button.fontSize,
      ];

      for (final size in sizes) {
        expect(size, isNotNull);
        expect(size!, greaterThanOrEqualTo(12));
      }
    });

    test('body text is 16px, as the guidelines require', () {
      expect(BrandType.body.fontSize, 16);
    });

    test('motion timings sit in the documented bands', () {
      expect(BrandMotion.fast.inMilliseconds, inInclusiveRange(120, 180));
      expect(BrandMotion.standard.inMilliseconds, inInclusiveRange(200, 280));
      expect(BrandMotion.large.inMilliseconds, inInclusiveRange(300, 400));
    });
  });

  group('the themes', () {
    test('both use Inter with an Arabic-script fallback', () {
      for (final theme in [BrandTheme.light, BrandTheme.dark]) {
        expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
        expect(
          theme.textTheme.bodyLarge?.fontFamilyFallback,
          contains('Noto Sans Arabic'),
        );
      }
    });

    test('controls are at least the preferred touch target', () {
      final button = BrandTheme.light.elevatedButtonTheme.style;
      final size = button?.minimumSize?.resolve({});

      expect(size?.height, BrandSizing.touchTargetPreferred);
    });
  });
}
