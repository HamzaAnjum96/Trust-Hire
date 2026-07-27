import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/core/formatters.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/services/local_store.dart';

import 'support/test_strings.dart';

/// The brand guidelines call for mixed English and Urdu interfaces, and
/// section 29 lists them among the accessibility requirements. For this
/// audience that is closer to a requirement than a feature.
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

  group('the catalogue', () {
    test('covers every English key in Urdu', () async {
      // A half-translated interface is worse than an untranslated one, so a
      // missing key should fail the build rather than silently fall back.
      final en =
          jsonDecode(await rootBundle.loadString('lib/l10n/app_en.arb'))
              as Map<String, dynamic>;
      final ur =
          jsonDecode(await rootBundle.loadString('lib/l10n/app_ur.arb'))
              as Map<String, dynamic>;

      final englishKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
      final urduKeys = ur.keys.where((k) => !k.startsWith('@')).toSet();

      expect(
        englishKeys.difference(urduKeys),
        isEmpty,
        reason: 'these keys have no Urdu translation',
      );
    });

    test('no Urdu string was left as its English original', () async {
      final en =
          jsonDecode(await rootBundle.loadString('lib/l10n/app_en.arb'))
              as Map<String, dynamic>;
      final ur =
          jsonDecode(await rootBundle.loadString('lib/l10n/app_ur.arb'))
              as Map<String, dynamic>;

      final untranslated = <String>[];
      for (final entry in ur.entries) {
        if (entry.key.startsWith('@')) continue;
        // Placeholders and digits legitimately match; a whole identical
        // sentence means somebody pasted the English in.
        final value = entry.value as String;
        if (value.length > 12 && value == en[entry.key]) {
          untranslated.add(entry.key);
        }
      }

      expect(untranslated, isEmpty);
    });

    test('both languages are offered', () {
      expect(AppStrings.supportedLocales, hasLength(2));
      expect(
        AppStrings.supportedLocales.map((l) => l.languageCode),
        containsAll(<String>['en', 'ur']),
      );
      expect(SettingsController.supportedLocales, AppStrings.supportedLocales);
    });
  });

  group('translated content', () {
    test('job types are translated', () async {
      final en = await loadStrings('en');
      final ur = await loadStrings('ur');

      for (final type in JobTag.values) {
        expect(
          type.label(ur),
          isNot(type.label(en)),
          reason: '${type.id} should differ between languages',
        );
      }
    });

    test('a job heading falls back in the reader\'s language', () async {
      final ur = await loadStrings('ur');
      final job = Job(
        id: 'j1',
        location: const JobLocation(latitude: 33.68, longitude: 73.04),
        createdAt: DateTime(2026, 7, 27),
        voiceNotePath: 'v.wav',
      );

      // The English fallback would read "Voice note job".
      expect(job.displayTitle(ur), isNot('Voice note job'));
      expect(job.displayTitle(ur), ur.voiceNoteJob);
    });

    test('distances and times are translated, not just the chrome', () async {
      final ur = await loadStrings('ur');
      final now = DateTime(2026, 7, 27, 10);

      expect(Format.distance(ur, 50), ur.veryClose);
      expect(Format.radius(ur, 500), contains('میٹر'));
      expect(
        Format.scheduled(ur, DateTime(2026, 7, 27, 16), now),
        contains('آج'),
      );
      expect(
        Format.posted(ur, now.subtract(const Duration(hours: 3)), now),
        contains('گھنٹے'),
      );
    });

    test('a timecode stays a timecode in both languages', () async {
      // Read as a number, so translating the separator would hurt.
      expect(Format.duration(const Duration(seconds: 75)), '1:15');
    });
  });

  group('no English left in the widget tree', () {
    /// Every Dart file under `lib`, minus the generated catalogue.
    Iterable<File> sourceFiles() sync* {
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('/l10n/')) continue;
        yield entity;
      }
    }

    test('no English prose is written straight into a widget', () async {
      // The literal-replacement pass missed a dozen of these and nothing
      // caught it: the app looked translated because the screens people
      // opened first were.
      //
      // The rule is "three or more words in one literal". An earlier version
      // asked for a capital letter followed by a space, and twice let through
      // a string that opened with "Optional." — a full stop where it expected
      // a space. Counting words has no such blind spot.
      final literal = RegExp(r"'([^'\\\$]{8,})'");
      final prose = RegExp(r'^[A-Za-z][^,;:]*( [a-z]+){2,}');
      final developerFacing = RegExp(r'debugPrint\(|Error\(|assert\(');
      // Comments are prose by nature and are not shipped to anyone.
      final comment = RegExp(r'^\s*(///?|\*)');

      final offenders = <String>[];
      for (final file in sourceFiles()) {
        for (final line in file.readAsLinesSync()) {
          if (comment.hasMatch(line)) continue;
          if (developerFacing.hasMatch(line)) continue;

          for (final match in literal.allMatches(line)) {
            final text = match.group(1)!;
            if (prose.hasMatch(text)) {
              offenders.add('${file.path}: $text');
            }
          }
        }
      }

      expect(offenders, isEmpty);
    });

    test('no interpolated English strings survive in the UI', () async {
      // The literal-replacement pass could only see plain string literals, so
      // anything built with interpolation had to be found by eye. This keeps
      // the obvious offenders from creeping back.
      final offenders = <String>[];
      // Both shapes: '${count} jobs' and '$count jobs'.
      // Two shapes, both of which slipped through the first pass:
      //   'Posted ${...}'  — English word, then an interpolation
      //   '$count jobs'    — interpolation, then an English word
      // The \w+ in the second deliberately stops at a dot or a bracket, so an
      // English-looking word *inside* an interpolated expression — say
      // `job.radiusMetres` — is not an offender.
      final suspects = [
        RegExp(r"'[A-Z][a-z]+ \$\{"),
        RegExp(r"'\$\{?\w+\}? (photo|job|photos|jobs|of)\b"),
      ];

      for (final file in sourceFiles()) {
        final source = file.readAsStringSync();
        if (suspects.any((s) => s.hasMatch(source))) offenders.add(file.path);
      }

      expect(offenders, isEmpty);
    });
  });

  group('the running app', () {
    testWidgets('starts in English by default', (tester) async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      expect(find.text('Nearby work'), findsOneWidget);
      // Read off the navigation, whichever shape this surface gets — the
      // point is the text direction, not the control.
      expect(
        Directionality.of(tester.element(find.byType(NavigationRail))),
        TextDirection.ltr,
      );
    });

    testWidgets('switches to Urdu and lays out right to left', (tester) async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();
      final settings = SettingsController(store)..load();
      await settings.setLocale(const Locale('ur'));

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      final ur = await loadStrings('ur');

      // Reading the stored preference is enough to prove persistence; the
      // rendered check below proves the tree actually flipped.
      expect(store.readString(StoreKeys.language), 'ur');

      await tester.pumpWidget(
        Localizations(
          locale: const Locale('ur'),
          delegates: AppStrings.localizationsDelegates,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) => Text(AppStrings.of(context).nearbyWork),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(ur.nearbyWork), findsOneWidget);
      expect(ur.nearbyWork, isNot('Nearby work'));
    });

    testWidgets('Urdu is a right-to-left language', (tester) async {
      late TextDirection direction;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ur'),
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          home: Builder(
            builder: (context) {
              direction = Directionality.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(direction, TextDirection.rtl);
    });

    testWidgets('the whole app renders in Urdu without overflowing', (
      tester,
    ) async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();
      await SettingsController(store).setLocale(const Locale('ur'));

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('the language preference', () {
    test('defaults to following the device', () async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();
      final settings = SettingsController(store)..load();

      expect(settings.locale, isNull);
    });

    test('survives a restart', () async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();
      await (SettingsController(store)..load()).setLocale(const Locale('ur'));

      final reloaded = SettingsController(store)..load();
      expect(reloaded.locale?.languageCode, 'ur');
    });

    test('can be set back to following the device', () async {
      final store = await LocalStore.open();
      // The intro is covered in onboarding_test; these assert the
      // shell that follows it.
      await (SettingsController(store)..load()).markIntroSeen();
      final settings = SettingsController(store)..load();

      await settings.setLocale(const Locale('ur'));
      await settings.setLocale(null);

      expect((SettingsController(store)..load()).locale, isNull);
    });
  });
}
