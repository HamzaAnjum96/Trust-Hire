import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/features/wallet/stripe_links.dart';
import 'package:trust_hire/features/wallet/stripe_return.dart';
import 'package:trust_hire/features/wallet/top_up_sheet.dart';
import 'package:trust_hire/models/wallet.dart';
import 'package:trust_hire/services/local_store.dart';

import 'support/harness.dart';

/// Stripe, in test mode, through Payment Links.
///
/// There is no server: what is under test is what the app believes. It
/// credits a payment once however often it is told about it, it credits only
/// a top-up this browser started, for the amount it started, and it never
/// credits a payment that was not for this wallet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  group('the ledger', () {
    test('a payment buys tokens once, however often it is reported', () async {
      final wallet = WalletController(await LocalStore.open())..load();

      expect(
        await wallet.creditPayment(paymentId: 'cs_test_1', tokens: 1000),
        isTrue,
      );
      expect(
        await wallet.creditPayment(paymentId: 'cs_test_1', tokens: 1000),
        isFalse,
      );
      expect(
        await wallet.creditPayment(paymentId: 'cs_test_1', tokens: 5000),
        isFalse,
      );

      expect(wallet.balance, 1000);
      expect(wallet.hasCredited('cs_test_1'), isTrue);
    });

    test('the payment it came from survives a restart', () async {
      final store = await LocalStore.open();
      await (WalletController(
        store,
      )..load()).creditPayment(paymentId: 'cs_test_1', tokens: 2500);

      final reopened = WalletController(store)..load();
      expect(reopened.wallet.entries.single.paymentId, 'cs_test_1');
      expect(reopened.wallet.entries.single.kind, WalletEntryKind.topUp);
      expect(
        await reopened.creditPayment(paymentId: 'cs_test_1', tokens: 2500),
        isFalse,
      );
      expect(reopened.balance, 2500);
    });

    test('a simulated top-up has no payment', () async {
      final wallet = WalletController(await LocalStore.open())..load();
      await wallet.topUp(500);
      expect(wallet.wallet.entries.single.paymentId, isNull);
      expect(
        wallet.wallet.entries.single.toJson().containsKey('paymentId'),
        isFalse,
      );
    });
  });

  group('the sheet', () {
    testWidgets('off the GitHub Pages site it is the simulation, and says so', (
      tester,
    ) async {
      final store = (await tester.runAsync(LocalStore.open))!;
      final wallet = WalletController(store)..load();
      final opened = <Uri>[];

      await tester.pumpWidget(
        appHarness(
          store: store,
          wallet: wallet,
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TopUpSheet(
                      openPaymentLink: (url) async {
                        opened.add(url);
                        return true;
                      },
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No real payment is taken'), findsOneWidget);
      await tester.tap(find.text('Add Rs. 500'));
      await tester.pumpAndSettle();

      expect(wallet.balance, 500);
      expect(opened, isEmpty);
    });
  });

  /// GitHub Pages has no server, so it sells tokens through Stripe Payment
  /// Links and believes a return only as far as the browser can vouch for it.
  group('on GitHub Pages', () {
    final now = DateTime(2026, 10, 24, 22);
    final site = Uri.parse(StripePaymentLinks.site);
    Uri returning(String query) => site.replace(query: query);

    test('a return is read from the address, and only a real one', () {
      final ok = StripeReturn.from(
        returning('topup=1000&session=cs_test_abc123'),
      )!;
      expect(ok.tokens, 1000);
      expect(ok.sessionId, 'cs_test_abc123');

      for (final query in [
        'topup=1000&session=cs_live_abc123', // never real money
        'topup=999&session=cs_test_abc123', // not a package anybody sells
        'topup=1000', // no session
        'session=cs_test_abc123', // no amount
        'topup=lots&session=cs_test_abc123',
        'topup=1000&session=cs_test_<script>',
        '',
      ]) {
        expect(StripeReturn.from(returning(query)), isNull, reason: query);
      }
    });

    test('the address bar is tidied, and keeps anything else it had', () {
      final cleaned = StripeReturn.cleaned(
        Uri.parse(
          '${StripePaymentLinks.site}?topup=1000&session=cs_test_a&lang=ur#/',
        ),
      );
      expect(cleaned.queryParameters, {'lang': 'ur'});
      expect(cleaned.fragment, '/');
      expect(cleaned.path, site.path);
      expect(
        StripeReturn.cleaned(
          returning('topup=1000&session=cs_test_a'),
        ).toString(),
        StripePaymentLinks.site,
      );
    });

    test('links are offered only where they come back to', () {
      expect(StripePaymentLinks.returnsTo(site), isTrue);
      // Storage is per origin, so another path on the same site still works.
      expect(
        StripePaymentLinks.returnsTo(site.replace(path: '/trust-hire/')),
        isTrue,
      );
      expect(
        StripePaymentLinks.returnsTo(
          Uri.parse('http://localhost:8099/Trust-Hire/'),
        ),
        isFalse,
      );
      expect(
        StripePaymentLinks.returnsTo(Uri.parse('file:///app/index.html')),
        isFalse,
      );
      // Every package has a link, and every link is a test one.
      expect(StripePaymentLinks.byTokens.keys, TopUpSheet.packages);
      for (final link in StripePaymentLinks.byTokens.values) {
        expect(link, startsWith('https://buy.stripe.com/test_'));
      }
    });

    test('a link carries which account is paying', () {
      final link = StripePaymentLinks.withAccount(
        'https://buy.stripe.com/test_x',
        'user-002',
      );
      expect(link.queryParameters['client_reference_id'], 'user-002');
    });

    group('the return', () {
      final paid = StripeReturn(sessionId: 'cs_test_abc', tokens: 1000);

      Future<WalletController> walletFor([String? account]) async {
        final wallet = WalletController(await LocalStore.open())..load();
        if (account != null) wallet.setAccount(account);
        return wallet;
      }

      test('credits a top-up this browser started, once', () async {
        final wallet = await walletFor();
        await wallet.notePendingTopUp(1000, at: now);

        expect(
          await wallet.completeStripeReturn(paid, at: now),
          StripeReturnOutcome.credited,
        );
        expect(wallet.balance, 1000);
        expect(wallet.wallet.entries.single.paymentId, 'cs_test_abc');
        expect(wallet.pendingTopUp, isNull);

        // The same return again — a reload, a bookmark — finds nothing pending.
        expect(
          await wallet.completeStripeReturn(paid, at: now),
          StripeReturnOutcome.notStartedHere,
        );
        // And even with another top-up pending, a session buys tokens once.
        await wallet.notePendingTopUp(1000, at: now);
        expect(
          await wallet.completeStripeReturn(paid, at: now),
          StripeReturnOutcome.alreadyCredited,
        );
        expect(wallet.balance, 1000);
      });

      test('a return nobody here started is ignored', () async {
        final wallet = await walletFor();
        expect(
          await wallet.completeStripeReturn(paid, at: now),
          StripeReturnOutcome.notStartedHere,
        );
        expect(wallet.balance, 0);
      });

      test('a return for another amount is not credited', () async {
        final wallet = await walletFor();
        await wallet.notePendingTopUp(500, at: now);
        expect(
          await wallet.completeStripeReturn(paid, at: now),
          StripeReturnOutcome.notMatched,
        );
        expect(wallet.balance, 0);
        expect(
          wallet.pendingTopUp,
          isNotNull,
          reason: 'the 500 may still come back',
        );
      });

      test(
        "a return for somebody else's top-up is not credited here",
        () async {
          final wallet = await walletFor('user-002');
          await wallet.notePendingTopUp(1000, at: now);
          wallet.setAccount('user-003');
          expect(
            await wallet.completeStripeReturn(paid, at: now),
            StripeReturnOutcome.notMatched,
          );
          expect(wallet.balance, 0);
        },
      );

      test('a top-up started more than a day ago no longer counts', () async {
        final wallet = await walletFor();
        await wallet.notePendingTopUp(
          1000,
          at: now.subtract(const Duration(hours: 25)),
        );
        expect(
          await wallet.completeStripeReturn(paid, at: now),
          StripeReturnOutcome.notStartedHere,
        );
        expect(wallet.balance, 0);
      });
    });

    testWidgets('the sheet sends the payer to the link, having noted it', (
      tester,
    ) async {
      final store = (await tester.runAsync(LocalStore.open))!;
      final wallet = WalletController(store)..load();
      final opened = <Uri>[];

      await tester.pumpWidget(
        appHarness(
          store: store,
          wallet: wallet,
          child: Scaffold(
            body: TopUpSheet(
              paymentLinks: StripePaymentLinks.byTokens,
              openPaymentLink: (url) async {
                opened.add(url);
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Stripe brings you back here'),
        findsOneWidget,
      );
      expect(find.textContaining('not checked by a server'), findsOneWidget);
      await tester.tap(find.text('Pay Rs. 1,000 with Stripe'));
      await tester.pumpAndSettle();

      expect(
        opened.single.toString(),
        startsWith(StripePaymentLinks.byTokens[1000]!),
      );
      expect(
        opened.single.queryParameters['client_reference_id'],
        'local-user',
      );
      expect(wallet.pendingTopUp?.tokens, 1000);
      expect(wallet.pendingTopUp?.account, 'local-user');
      expect(
        wallet.balance,
        0,
        reason: 'nothing is credited until Stripe sends them back',
      );
    });

    group('coming back to the app', () {
      Future<LocalStore> pumpReturn(
        WidgetTester tester,
        String query, {
        int? started,
      }) async {
        final store = (await tester.runAsync(LocalStore.open))!;
        await tester.runAsync(
          () => (SettingsController(store)..load()).markIntroSeen(),
        );
        if (started != null) {
          await tester.runAsync(
            () => (WalletController(store)..load()).notePendingTopUp(started),
          );
        }

        await tester.pumpWidget(
          TrustHireApp(store: store, location: returning(query)),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        return store;
      }

      testWidgets('credits the payment and says so', (tester) async {
        final store = await pumpReturn(
          tester,
          'topup=1000&session=cs_test_back123',
          started: 1000,
        );

        expect(find.text('Rs. 1,000 added to your wallet.'), findsOneWidget);
        final reread = WalletController(store)..load();
        expect(reread.balance, 1000);
        expect(reread.hasCredited('cs_test_back123'), isTrue);
      });

      testWidgets('ignores a return address nobody here used', (tester) async {
        final store = await pumpReturn(
          tester,
          'topup=10000&session=cs_test_forged',
        );

        expect(find.textContaining('added to your wallet'), findsNothing);
        expect((WalletController(store)..load()).balance, 0);
      });
    });
  });
}
