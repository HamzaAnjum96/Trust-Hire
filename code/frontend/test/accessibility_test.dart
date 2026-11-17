import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/core/roles.dart';
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

    // **Every role pair the app draws, in both themes.** Since 0.24 the
    // palette lives in AppColours, so this checks the roles rather than a
    // list of brand colours somebody had to keep in step by hand — and a
    // reskin is held to it the moment its values change.
    for (final (name, roles) in [
      ('light', AppColours.light),
      ('dark', AppColours.dark),
    ]) {
      test('every text role clears AA on what it sits on ($name)', () {
        final pairs = <String, (Color, Color)>{
          'text on page': (roles.text, roles.page),
          'text on surface': (roles.text, roles.surface),
          'text on raised': (roles.text, roles.raised),
          'text on tint': (roles.text, roles.tint),
          'text on selection': (roles.text, roles.selection),
          'muted on page': (roles.textMuted, roles.page),
          'muted on surface': (roles.textMuted, roles.surface),
          'muted on raised': (roles.textMuted, roles.raised),
          'muted on tint': (roles.textMuted, roles.tint),
          'accent text on page': (roles.accentText, roles.page),
          'accent text on surface': (roles.accentText, roles.surface),
          'accent text on raised': (roles.accentText, roles.raised),
          'on action': (roles.onAction, roles.action),
          'on highlight': (roles.onHighlight, roles.highlight),
          'on voice': (roles.onVoice, roles.voice),
          'voice on surface': (roles.voice, roles.surface),
          'on good': (roles.onSignal, roles.good),
          'on bad': (roles.onSignal, roles.bad),
          'on info': (roles.onSignal, roles.info),
          'bad on surface': (roles.bad, roles.surface),
          'good on surface': (roles.good, roles.surface),
          'warn on surface': (roles.warn, roles.surface),
          'info on surface': (roles.info, roles.surface),
          'fare on surface': (roles.fare, roles.surface),
          'on avatar': (roles.onAvatar, roles.avatar),
          'on inverse': (roles.onInverse, roles.inverse),
          'on shell': (roles.onShell, roles.shell),
          'quiet on shell': (roles.shellMuted, roles.shell),
        };
        pairs.forEach((pair, colours) {
          expect(
            contrast(colours.$1, colours.$2),
            greaterThanOrEqualTo(4.5),
            reason: '$pair ($name) must clear WCAG AA for normal text',
          );
        });
      });

      test('borders and the shell indicator clear 3:1 ($name)', () {
        // WCAG 1.4.11: a control's boundary, and the mark that says which
        // destination is selected.
        expect(
          contrast(roles.lineStrong, roles.surface),
          greaterThanOrEqualTo(3),
        );
        expect(contrast(roles.highlight, roles.shell), greaterThanOrEqualTo(3));
      });
    }

    test('turmeric is never text on white, which is why accentText exists', () {
      // 1.8:1. The signature colour carries ink on top of it; as words it is
      // the darker turmericText.
      expect(
        contrast(AppColours.light.highlight, AppColours.light.surface),
        lessThan(3),
      );
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
    test(
      'both use Atkinson Hyperlegible Next with an Arabic-script fallback',
      () {
        for (final theme in [BrandTheme.light, BrandTheme.dark]) {
          expect(
            theme.textTheme.bodyLarge?.fontFamily,
            'Atkinson Hyperlegible Next',
          );
          expect(
            theme.textTheme.bodyLarge?.fontFamilyFallback,
            contains('Noto Sans Arabic'),
          );
        }
      },
    );

    test('controls are at least the preferred touch target', () {
      final button = BrandTheme.light.elevatedButtonTheme.style;
      final size = button?.minimumSize?.resolve({});

      // 52 since 0.24, above the preferred 48: a chunky pill for one hand.
      expect(size?.height, BrandSizing.controlHeight);
      expect(
        BrandSizing.controlHeight,
        greaterThanOrEqualTo(BrandSizing.touchTargetPreferred),
      );
    });
  });
}
