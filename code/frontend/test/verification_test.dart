import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/bootstrap.dart';
import 'package:trust_hire/app/verification_controller.dart';
import 'package:trust_hire/features/verification/verification_screen.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/features/verification/verification_rules.dart';
import 'package:trust_hire/models/admin.dart';
import 'package:trust_hire/models/verification.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/seed_loader.dart';
import 'package:trust_hire/services/sms_sender.dart';

import 'support/surface.dart';

/// Section 2 — what the app can honestly say about who somebody is.
///
/// The load-bearing test in this file is "the whole number never reaches
/// storage". Everything else here is a rule that can be argued about; that one
/// is the difference between holding a national identity number and not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const rules = VerificationRules();

  group('the CNIC number', () {
    test('takes thirteen digits, punctuated or not', () {
      expect(rules.normaliseCnic('35202-1234567-1'), '35202-1234567-1');
      expect(rules.normaliseCnic('3520212345671'), '35202-1234567-1');
      expect(rules.normaliseCnic(' 35202 1234567 1 '), '35202-1234567-1');

      // A keypad has no dash, and refusing thirteen correct digits over
      // punctuation is the kind of thing that stops somebody using the app.
      expect(rules.isPlausibleCnic('3520212345671'), isTrue);
    });

    test('refuses anything that is not thirteen digits', () {
      expect(rules.isPlausibleCnic('35202-123456-1'), isFalse);
      expect(rules.isPlausibleCnic('35202-12345678-1'), isFalse);
      expect(rules.isPlausibleCnic('abcde-fghijkl-m'), isFalse);
      expect(rules.isPlausibleCnic(''), isFalse);
      expect(rules.isPlausibleCnic(null), isFalse);
    });

    test('keeps the last two digits and the check digit, and nothing else', () {
      expect(rules.mask('35202-1234567-1'), '*****-*****67-1');
      expect(rules.mask('3520212345671'), '*****-*****67-1');
    });

    test('masks nothing it cannot parse', () {
      // Otherwise a number the mask did not recognise would be the one number
      // stored whole.
      expect(rules.mask('35202-123456-1'), isNull);
      expect(rules.mask('not a number'), isNull);
    });

    test('is a shape check and says so, not an identity check', () {
      // A well-formed number with no name behind it is not plausible: Section
      // 2 asks for "valid CNIC number format, name/DOB present", all three.
      final adult = DateTime(1990, 5, 4);

      expect(
        rules.isPlausibleCard(
          number: '35202-1234567-1',
          name: 'Usman Raza',
          dateOfBirth: adult,
        ),
        isTrue,
      );
      expect(
        rules.isPlausibleCard(number: '35202-1234567-1', name: 'Usman Raza'),
        isFalse,
      );
      expect(
        rules.isPlausibleCard(
          number: '35202-1234567-1',
          name: '',
          dateOfBirth: adult,
        ),
        isFalse,
      );
      expect(
        rules.isPlausibleCard(
          number: '35202-1234567-1',
          name: 'Usman Raza',
          dateOfBirth: DateTime(2020, 1, 1),
        ),
        isFalse,
      );
    });
  });

  group('the phone number', () {
    test('four spellings of one number are one number', () {
      // Which matters because the fraud loophole this closes is about *which*
      // number, and four spellings would be four accounts.
      for (final written in [
        '03001234567',
        '3001234567',
        '+92 300 1234567',
        '0092-300-1234567',
      ]) {
        expect(rules.normalisePhone(written), '+923001234567', reason: written);
      }
    });

    test('refuses what is not a Pakistani mobile', () {
      expect(rules.normalisePhone('0421234567'), isNull); // a landline
      expect(rules.normalisePhone('030012345'), isNull); // too short
      expect(rules.normalisePhone('+441234567890'), isNull);
      expect(rules.normalisePhone(''), isNull);
    });

    test('is shown the way it is read aloud', () {
      expect(rules.formatPhone('+923001234567'), '+92 300 1234567');
    });
  });

  group('the CNIC-SIM name check', () {
    test('is generous about how a name is written', () {
      // It is aimed at "bought a new SIM after a ban", which produces an
      // entirely different name — not at spelling.
      expect(rules.namesMatch('Usman Raza', 'usman  raza'), isTrue);
      expect(rules.namesMatch('Muhammad Usman Raza', 'Mohammad Usman Raza'),
          isTrue);
      expect(rules.namesMatch('Md Usman Raza', 'Muhammad Usman Raza'), isTrue);
      expect(rules.namesMatch('Mr Usman Raza', 'Usman Raza'), isTrue);
      expect(rules.namesMatch('Usman Raza', 'Usman Ahmed Raza'), isTrue);
    });

    test('catches a different person', () {
      expect(rules.namesMatch('Usman Raza', 'Bilal Awan'), isFalse);
      expect(rules.namesMatch('Usman Raza', ''), isFalse);
      expect(rules.namesMatch(null, 'Usman Raza'), isFalse);
    });

    test('a shared family name alone is not a match', () {
      // A great many people share a family name, and treating that as the same
      // person would make the check worthless in the country it is for.
      expect(rules.namesMatch('Usman Raza', 'Sana Raza'), isFalse);
    });
  });

  group('the code', () {
    PhoneChallenge challengeAt(DateTime sentAt, {int attempts = 0}) =>
        PhoneChallenge(
          phone: '+923001234567',
          code: '123456',
          sentAt: sentAt,
          attempts: attempts,
        );

    final sent = DateTime(2026, 7, 28, 10);

    test('is six digits', () {
      final rng = Random(7);
      for (var i = 0; i < 50; i++) {
        final code = VerificationRules(random: rng).newCode();
        expect(code.length, VerificationRules.codeLength);
        expect(int.tryParse(code), isNotNull);
      }
    });

    test('the right code, in time, is confirmed', () {
      expect(
        rules.check(challengeAt(sent), '123456',
            now: sent.add(const Duration(minutes: 1))),
        PhoneCheckResult.confirmed,
      );
    });

    test('a late right code is expired, not wrong', () {
      // The honest answer to "I typed it correctly and it said wrong" is that
      // the code had run out. A screen that cannot tell those apart teaches
      // people to distrust the one that is their own fault.
      expect(
        rules.check(challengeAt(sent), '123456',
            now: sent.add(const Duration(minutes: 6))),
        PhoneCheckResult.expired,
      );
    });

    test('runs out of guesses', () {
      expect(
        rules.check(
          challengeAt(sent, attempts: VerificationRules.maxAttempts),
          '123456',
          now: sent.add(const Duration(minutes: 1)),
        ),
        PhoneCheckResult.tooManyAttempts,
      );
    });

    test('nothing sent is its own answer', () {
      expect(rules.check(null, '123456'), PhoneCheckResult.nothingSent);
    });

    test('the resend cooldown counts down and then clears', () {
      expect(
        rules.resendWaitFor(challengeAt(sent), now: sent),
        VerificationRules.resendAfter,
      );
      expect(
        rules.resendWaitFor(challengeAt(sent),
            now: sent.add(const Duration(seconds: 31))),
        Duration.zero,
      );
    });
  });

  group('submitting, end to end', () {
    late LocalStore store;
    late VerificationController controller;
    late DemoSmsSender sms;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = LocalStore(await SharedPreferences.getInstance());
      sms = DemoSmsSender();
      controller = VerificationController(store, sms: sms)..load();
      controller.setAccount('user-009', name: 'Usman Raza');
    });

    test('a new account has submitted nothing', () {
      expect(controller.mine.isEmpty, isTrue);
      expect(controller.mine.stepsDone, 0);
      expect(controller.mine.cnicOnFile, isFalse);
    });

    test('the whole CNIC number never reaches storage', () async {
      // **The one that matters.** Section 13 rules out looking a CNIC up, so a
      // complete national identity number is something the app would be
      // holding for no reason anybody could name.
      await controller.submitCnic(
        number: '35202-1234567-1',
        name: 'Usman Raza',
        dateOfBirth: DateTime(1990, 5, 4),
      );

      final everythingStored = jsonEncode({
        'reviews': store.readCollection(StoreKeys.accountReviews),
        'cnics': store.readCollection(StoreKeys.cnicRecords),
      });

      expect(everythingStored, contains('*****-*****67-1'));
      expect(everythingStored, isNot(contains('35202')));
      expect(everythingStored, isNot(contains('1234567')));

      // And nothing anywhere that looks like a run of CNIC digits — a blunter
      // guard than the two above, so a future field that quietly carried the
      // number would fail here even under a name nobody thought to check.
      //
      // Timestamps are taken out first. They are digits by nature and would
      // otherwise make this assertion fail on every record, which is a way to
      // end up deleting it.
      final withoutTimestamps = everythingStored.replaceAll(
        RegExp(r'\d{4}-\d{2}-\d{2}T[\d:.]+Z?'),
        '<when>',
      );
      expect(RegExp(r'\d{5}').hasMatch(withoutTimestamps), isFalse);
    });

    test('a number that is not thirteen digits stores nothing at all', () async {
      final accepted = await controller.submitCnic(
        number: '35202-12345-1',
        name: 'Usman Raza',
        dateOfBirth: DateTime(1990, 5, 4),
      );

      expect(accepted, isFalse);
      expect(controller.mine.cnicOnFile, isFalse);
      expect(store.readCollection(StoreKeys.cnicRecords) ?? const [], isEmpty);
    });

    test('a card the check cannot confirm is still stored, and flagged',
        () async {
      // Section 2 sends these to a person rather than turning them away. An
      // upload the app silently discards is one the worker thinks succeeded.
      final accepted = await controller.submitCnic(
        number: '35202-1234567-1',
        name: 'Usman Raza',
      );

      expect(accepted, isTrue);
      expect(controller.mine.cnicOnFile, isTrue);
      expect(controller.mine.cnicPlausible, isFalse);
    });

    test('a phone is confirmed by answering the code', () async {
      final sentOk = await controller.sendCode('0300 1234567');
      expect(sentOk, isTrue);
      expect(sms.sent, 1);
      expect(controller.mine.phone, '+923001234567');

      // Not yet — sending is not confirming.
      expect(controller.mine.phoneVerified, isFalse);

      final result = await controller.confirmCode(controller.challenge!.code);
      expect(result, PhoneCheckResult.confirmed);
      expect(controller.mine.phoneVerified, isTrue);

      // The challenge is finished, so the same code cannot be replayed.
      expect(controller.challenge, isNull);
    });

    test('a wrong code costs an attempt and survives a reload', () async {
      // Otherwise closing the app would be a way to get a fresh set of
      // guesses, and the attempt limit would mean nothing.
      await controller.sendCode('03001234567');
      await controller.confirmCode('000000');
      expect(controller.challenge!.attempts, 1);

      final reopened = VerificationController(store, sms: sms)
        ..setAccount('user-009', name: 'Usman Raza');

      expect(reopened.challenge!.attempts, 1);
    });

    test('a resend to the same number waits, a correction does not', () async {
      final at = DateTime(2026, 7, 28, 10);

      expect(await controller.sendCode('03001234567', at: at), isTrue);
      expect(
        await controller.sendCode('03001234567',
            at: at.add(const Duration(seconds: 5))),
        isFalse,
        reason: 'resend cannot be used to spray messages at a number',
      );

      // A typo should not mean waiting out a message that went to the wrong
      // phone.
      expect(
        await controller.sendCode('03009999999',
            at: at.add(const Duration(seconds: 5))),
        isTrue,
      );
    });

    test('a new number drops the tick the old one earned', () async {
      await controller.sendCode('03001234567');
      await controller.confirmCode(controller.challenge!.code);
      expect(controller.mine.phoneVerified, isTrue);

      await controller.sendCode('03007654321');

      // A verified tick beside a number nobody has ever sent anything to is
      // the one outcome this step must not produce.
      expect(controller.mine.phoneVerified, isFalse);
      expect(controller.mine.phone, '+923007654321');
    });

    test('a mismatched name flags, and changes nothing else', () async {
      await controller.submitCnic(
        number: '35202-1234567-1',
        name: 'Bilal Awan',
        dateOfBirth: DateTime(1990, 5, 4),
      );
      await controller.sendCode('03001234567');
      await controller.confirmCode(controller.challenge!.code);

      expect(controller.mine.isFlagged, isTrue);

      // Never a rejection. The account is exactly as usable as before.
      expect(controller.status, ReviewStatus.pending);
      expect(controller.mine.isComplete, isTrue);
      expect(
        controller.limits,
        contains(VerificationLimit.simMismatchIsNotGuilt),
      );
    });

    test('an account with no name to compare against is not flagged', () async {
      // The device account has no name — the interface calls it "This device".
      // Flagging it would fire the check on the one account that has done
      // nothing at all.
      final device = VerificationController(store, sms: sms)..load();

      await device.submitCnic(
        number: '35202-1234567-1',
        name: 'Somebody Else',
        dateOfBirth: DateTime(1990, 5, 4),
      );
      await device.sendCode('03001234567');
      await device.confirmCode(device.challenge!.code);

      expect(device.canCheckSimName, isFalse);
      expect(device.mine.isFlagged, isFalse);
    });

    test('the admin panel reads the same record the worker wrote', () async {
      // One row, not two. A second copy would disagree the first time somebody
      // re-submitted, and the one an approval was decided on would be
      // whichever the screen happened to read.
      await controller.submitCnic(
        number: '35202-1234567-1',
        name: 'Usman Raza',
        dateOfBirth: DateTime(1990, 5, 4),
      );

      final stored = (store.readCollection(StoreKeys.accountReviews) ?? const [])
          .map(AccountReview.fromJson)
          .firstWhere((review) => review.userId == 'user-009');

      expect(stored.cnicOnFile, isTrue);
      expect(stored.cnicPlausible, isTrue);
      expect(stored.verification.cnicMasked, '*****-*****67-1');
    });

    test('an approval decision is not undone by a re-submission', () async {
      // Status belongs to the platform; the verification belongs to the
      // account holder. Writing one must not overwrite the other.
      await store.writeCollection(StoreKeys.accountReviews, [
        const AccountReview(
          userId: 'user-009',
          status: ReviewStatus.approved,
          note: 'Looked fine.',
        ).toJson(),
      ]);
      controller.load();

      await controller.submitCnic(
        number: '35202-1234567-1',
        name: 'Usman Raza',
        dateOfBirth: DateTime(1990, 5, 4),
      );

      expect(controller.status, ReviewStatus.approved);
    });
  });

  group('what is on file already', () {
    test('a seeded record with no dates still reads as having a document', () {
      // The seed says *what* is on file without saying when, and a record
      // written before P1-9 existed must not read as an empty one.
      final verification = Verification.fromJson({
        'cnicOnFile': true,
        'cnicPlausible': true,
        'phoneVerified': true,
        'simNameMatches': false,
      });

      expect(verification.cnicOnFile, isTrue);
      expect(verification.phoneVerified, isTrue);
      expect(verification.isFlagged, isTrue);
      expect(verification.stepsDone, Verification.steps);
    });

    test('survives a round trip', () {
      final original = Verification(
        cnicMasked: '*****-*****67-1',
        cnicName: 'Usman Raza',
        cnicDateOfBirth: DateTime.utc(1990, 5, 4),
        cnicPlausible: true,
        cnicSubmittedAt: DateTime.utc(2026, 7, 1),
        phone: '+923001234567',
        phoneVerifiedAt: DateTime.utc(2026, 7, 2),
        simNameMatches: false,
      );

      final restored = Verification.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.cnicMasked, original.cnicMasked);
      expect(restored.cnicName, original.cnicName);
      expect(restored.cnicDateOfBirth, original.cnicDateOfBirth);
      expect(restored.cnicSubmittedAt, original.cnicSubmittedAt);
      expect(restored.phone, original.phone);
      expect(restored.phoneVerifiedAt, original.phoneVerifiedAt);
      expect(restored.simNameMatches, isFalse);
    });
  });

  group('what none of it establishes', () {
    test('a caveat travels with the signal it qualifies', () {
      // Rendered from the rules rather than written into the screen, so a
      // caveat cannot be dropped by editing a layout.
      expect(const VerificationRules().describeLimits(const Verification()),
          isEmpty);

      final submitted = const Verification().withCnic(
        masked: '*****-*****67-1',
        name: 'Usman Raza',
        plausible: true,
        at: DateTime(2026, 7, 1),
        simNameMatches: true,
      );

      expect(
        const VerificationRules().describeLimits(submitted),
        containsAll([
          VerificationLimit.noGovernmentLookup,
          VerificationLimit.photoUnreviewed,
        ]),
      );
    });
  });

  group('the screen, end to end', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      rootBundle.clear();
    });

    testWidgets('a person can get from nothing to a confirmed phone',
        (tester) async {
      await tester.useCompactSurface();

      final store = await bootstrap();
      final controller = VerificationController(store)
        ..setAccount('user-090', name: 'Naila Khan');

      await tester.pumpWidget(
        ChangeNotifierProvider<VerificationController>.value(
          value: controller,
          child: const MaterialApp(
            localizationsDelegates: AppStrings.localizationsDelegates,
            supportedLocales: AppStrings.supportedLocales,
            home: VerificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing submitted, and the screen leads with what none of this means
      // rather than with a form.
      expect(find.text('Nothing submitted yet'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'CNIC number'),
        '3520212345671',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Name, exactly as printed on the card'),
        'Naila Khan',
      );
      await tester.ensureVisible(find.text('Submit CNIC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit CNIC'));
      await tester.pumpAndSettle();

      // Shown as the mask, because the mask is all there is.
      expect(find.textContaining('*****-*****67-1'), findsOneWidget);


      // No date of birth, so the automated check cannot confirm it — and it
      // says so rather than either passing it or throwing the upload away.
      expect(
        find.textContaining('the automated check could not confirm'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Mobile number'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Mobile number'),
        '03001234567',
      );
      await tester.ensureVisible(find.text('Send me a code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send me a code'));
      await tester.pumpAndSettle();

      // The demo says, on screen, that nothing was actually sent.
      expect(
        find.textContaining('instead of arriving by SMS'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.widgetWithText(TextField, 'The 6-digit code'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'The 6-digit code'),
        controller.challenge!.code,
      );
      await tester.ensureVisible(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(controller.mine.phoneVerified, isTrue);
      expect(find.text('Phone confirmed'), findsWidgets);
    });

    testWidgets('the whole number is not left sitting in the field',
        (tester) async {
      // Masking at rest is worth little if the number stays on screen for
      // whoever picks the phone up next.
      await tester.useCompactSurface();

      final store = await bootstrap();
      final controller = VerificationController(store)
        ..setAccount('user-091', name: 'Naila Khan');

      await tester.pumpWidget(
        ChangeNotifierProvider<VerificationController>.value(
          value: controller,
          child: const MaterialApp(
            localizationsDelegates: AppStrings.localizationsDelegates,
            supportedLocales: AppStrings.supportedLocales,
            home: VerificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'CNIC number'),
        '35202-1234567-1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Name, exactly as printed on the card'),
        'Naila Khan',
      );
      await tester.ensureVisible(find.text('Submit CNIC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit CNIC'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1234567'), findsNothing);
    });
  });

  group('the seeded records', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      rootBundle.clear();
    });

    test('agree with the CNICs beside them', () async {
      // Two files describing the same submission. A masked number in one that
      // does not match the other would be a demo of a bug.
      const loader = SeedLoader();
      final reviews = await loader.loadReviews();
      final cnics = {
        for (final record in await loader.loadCnics()) record.userId: record,
      };

      for (final review in reviews) {
        if (!review.cnicOnFile) {
          expect(cnics.containsKey(review.userId), isFalse,
              reason: '${review.userId} has a CNIC nobody says is on file');
          continue;
        }

        final record = cnics[review.userId];
        expect(record, isNotNull,
            reason: '${review.userId} is said to have a CNIC on file');
        expect(review.verification.cnicMasked, record!.maskedNumber);
        expect(review.verification.cnicName, record.nameOnCard);
      }
    });

    test('carry numbers the app would accept', () async {
      // Stored in the form the app normalises to, so a seeded record and one a
      // person types are the same shape. A record the app's own rules would
      // reject is a demo of a state the app cannot produce.
      //
      // These are Pakistani prefixes with random suffixes, the same convention
      // the job contact numbers use. There is no reserved range in Pakistan
      // the way there is in the UK, so this is fiction by improbability rather
      // than by guarantee — worth saying plainly rather than claiming more.
      const loader = SeedLoader();

      for (final review in await loader.loadReviews()) {
        final phone = review.verification.phone;
        if (phone == null) continue;

        expect(const VerificationRules().normalisePhone(phone), phone,
            reason: '$phone is not in the form the app stores');
      }
    });

    test('date what they claim, rather than leaving it to a stand-in',
        () async {
      // The model has a stand-in date for records that say *what* is on file
      // without saying when. It must not reach a screen: "Confirmed 1 Jan"
      // from the year 2000 is worse than saying nothing.
      const loader = SeedLoader();
      final tenYears = DateTime.now().subtract(const Duration(days: 3650));

      for (final review in await loader.loadReviews()) {
        if (review.cnicOnFile) {
          expect(review.verification.cnicSubmittedAt!.isAfter(tenYears), isTrue,
              reason: '${review.userId} has a stand-in submission date');
        }
        if (review.phoneVerified) {
          expect(
            review.verification.phoneVerifiedAt!.isAfter(tenYears),
            isTrue,
            reason: '${review.userId} has a stand-in confirmation date',
          );
        }
      }
    });
  });
}
