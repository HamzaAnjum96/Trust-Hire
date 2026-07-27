import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/jobs/contact_panel.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/services/contact_launcher.dart';

import 'support/test_strings.dart';

/// A launcher that records what it was asked to open instead of opening it.
class _FakeLauncher implements ContactLauncher {
  _FakeLauncher({this.succeeds = true});

  bool succeeds;
  String? calledNumber;
  String? whatsAppedNumber;
  String? whatsAppMessage;

  @override
  Future<bool> call(String number) async {
    calledNumber = number;
    return succeeds;
  }

  @override
  Future<bool> whatsApp(String number, {required String message}) async {
    whatsAppedNumber = number;
    whatsAppMessage = message;
    return succeeds;
  }
}

/// The POC stopped at *finding* work, which made it impossible to test whether
/// anyone would act on it. Handing off to the phone and WhatsApp closes that
/// loop without a backend.
void main() {
  late AppStrings strings;

  setUpAll(() async => strings = await loadStrings());

  group('normalising a number', () {
    test('strips the spaces people actually type', () {
      expect(ContactLauncher.normalise('0300 4471902'), '03004471902');
      expect(ContactLauncher.normalise('0300-447-1902'), '03004471902');
      expect(ContactLauncher.normalise(' 0300 447 1902 '), '03004471902');
    });

    test('keeps a leading plus so international numbers survive', () {
      expect(ContactLauncher.normalise('+92 333 7761204'), '+923337761204');
    });
  });

  group('the WhatsApp number', () {
    test('swaps a local leading zero for the country code', () {
      // The single most common way a wa.me link fails: 0300… is meaningless
      // to WhatsApp, which wants 92300….
      expect(ContactLauncher.whatsAppNumber('0300 4471902'), '923004471902');
    });

    test('leaves an international number alone', () {
      expect(ContactLauncher.whatsAppNumber('+92 333 7761204'), '923337761204');
    });

    test('does not double the country code', () {
      expect(ContactLauncher.whatsAppNumber('923004471902'), '923004471902');
    });

    test('adds the country code to a bare local number', () {
      expect(ContactLauncher.whatsAppNumber('3004471902'), '923004471902');
    });

    test('refuses something too short to be a number', () {
      expect(ContactLauncher.whatsAppNumber('12345'), isNull);
      expect(ContactLauncher.whatsAppNumber(''), isNull);
    });
  });

  group('the contact panel', () {
    Future<void> pumpPanel(
      WidgetTester tester, {
      required ContactLauncher launcher,
      String number = '0300 4471902',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          theme: BrandTheme.light,
          home: Scaffold(
            body: ContactPanel(number: number, launcher: launcher),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('hides the number until it is asked for', (tester) async {
      await pumpPanel(tester, launcher: _FakeLauncher());

      // The product promises approximate locations; showing a phone number
      // unprompted alongside that would undercut it.
      expect(find.text('0300 4471902'), findsNothing);
      expect(find.text(strings.contactShow), findsOneWidget);
      expect(find.text(strings.contactHiddenNotice), findsOneWidget);
    });

    testWidgets('reveals it on a deliberate tap', (tester) async {
      await pumpPanel(tester, launcher: _FakeLauncher());

      await tester.tap(find.text(strings.contactShow));
      await tester.pumpAndSettle();

      expect(find.text('0300 4471902'), findsOneWidget);
      expect(find.text(strings.callNumber), findsOneWidget);
      expect(find.text(strings.whatsAppNumber), findsOneWidget);
    });

    testWidgets('hands the number to the dialler', (tester) async {
      final launcher = _FakeLauncher();
      await pumpPanel(tester, launcher: launcher);

      await tester.tap(find.text(strings.contactShow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.callNumber));
      await tester.pumpAndSettle();

      expect(launcher.calledNumber, '0300 4471902');
    });

    testWidgets('hands the number and a greeting to WhatsApp', (tester) async {
      final launcher = _FakeLauncher();
      await pumpPanel(tester, launcher: launcher);

      await tester.tap(find.text(strings.contactShow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.whatsAppNumber));
      await tester.pumpAndSettle();

      expect(launcher.whatsAppedNumber, '0300 4471902');
      expect(launcher.whatsAppMessage, strings.whatsAppMessage);
    });

    testWidgets('says so when the hand-off fails, and keeps the number', (
      tester,
    ) async {
      await pumpPanel(tester, launcher: _FakeLauncher(succeeds: false));

      await tester.tap(find.text(strings.contactShow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.callNumber));
      await tester.pumpAndSettle();

      expect(find.text(strings.couldNotOpenDialer), findsOneWidget);
      // The number stays on screen so the user can dial it themselves.
      expect(find.text('0300 4471902'), findsOneWidget);
    });

    testWidgets('copies the number to the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );

      await pumpPanel(tester, launcher: _FakeLauncher());
      await tester.tap(find.text(strings.contactShow));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(strings.copyNumber));
      await tester.pumpAndSettle();

      expect(copied, '0300 4471902');
      expect(find.text(strings.numberCopied), findsOneWidget);
    });
  });

  group('the job model', () {
    Job job({String? contact}) => Job(
      id: 'j1',
      location: const JobLocation(latitude: 33.68, longitude: 73.04),
      createdAt: DateTime(2026, 7, 27),
      title: 'Fix the gate',
      contactNumber: contact,
    );

    test('a contact number is optional like everything else', () {
      expect(job().hasContact, isFalse);
      expect(job(contact: '   ').hasContact, isFalse);
      expect(job(contact: '0300 4471902').hasContact, isTrue);
    });

    test('round-trips through JSON', () {
      final restored = Job.fromJson(job(contact: '0300 4471902').toJson());
      expect(restored.contactNumber, '0300 4471902');
    });

    test('copyWith can clear it', () {
      final withContact = job(contact: '0300 4471902');
      expect(
        withContact.copyWith(clearContactNumber: true).contactNumber,
        isNull,
      );
      expect(withContact.copyWith().contactNumber, '0300 4471902');
    });
  });
}
