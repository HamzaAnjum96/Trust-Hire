import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/dev_services_controller.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/features/wallet/stripe_links.dart';
import 'package:trust_hire/features/wallet/stripe_return.dart';
import 'package:trust_hire/features/wallet/top_up_sheet.dart';
import 'package:trust_hire/models/wallet.dart';
import 'package:trust_hire/services/local_store.dart';

import 'support/harness.dart';

/// Stripe, in test mode, through the dev server.
///
/// The server is a script here. What is under test is what the app believes:
/// it credits what Stripe charged rather than what it asked for, it credits a
/// payment once however often it is told about it, and it never credits a
/// payment that was not for this wallet.
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

  group('the address', () {
    test('what people type is taken, what nobody could mean is not', () {
      expect(
        DevServicesController.parse('localhost:8787').toString(),
        'http://localhost:8787',
      );
      expect(
        DevServicesController.parse(' http://192.168.1.5:8787 ').toString(),
        'http://192.168.1.5:8787',
      );
      expect(DevServicesController.parse('https://dev.example'), isNotNull);
      expect(DevServicesController.parse(''), isNull);
      expect(DevServicesController.parse('ftp://dev.example'), isNull);
      expect(DevServicesController.parse('http://'), isNull);
    });

    test('nothing is asked of the network until an address is set', () async {
      var calls = 0;
      final dev = DevServicesController(
        await LocalStore.open(),
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      )..load();
      await Future<void>.delayed(Duration.zero);

      expect(dev.isSet, isFalse);
      expect(calls, 0);
    });

    test('a server that does not answer is reported as such', () async {
      final dev = DevServicesController(
        await LocalStore.open(),
        client: MockClient((_) async => throw http.ClientException('refused')),
      );
      await dev.setUrl('localhost:8787');
      expect(dev.unreachable, isTrue);
      expect(dev.paymentsReady, isFalse);
      expect(dev.agentReady, isFalse);
    });
  });

  group('the sheet', () {
    /// A dev server whose sessions are paid on the [paidAfter]th look.
    MockClient stripeServer({
      int paidAfter = 2,
      String account = 'local-user',
      int tokens = 1000,
      String status = 'complete',
      List<http.Request>? log,
    }) {
      var looks = 0;
      return MockClient((request) async {
        log?.add(request);
        final path = request.url.path;
        if (path == '/health') {
          return http.Response(
            jsonEncode({
              'payments': {'enabled': true},
              'fareAgent': {'enabled': false},
            }),
            200,
          );
        }
        if (path == '/payments/checkout') {
          return http.Response(
            jsonEncode({
              'id': 'cs_test_abc',
              'url': 'https://checkout.stripe.com/c/pay/cs_test_abc',
            }),
            200,
          );
        }
        looks++;
        return http.Response(
          jsonEncode({
            'id': 'cs_test_abc',
            'status': status,
            'paid': looks >= paidAfter && status == 'complete',
            'tokens': tokens,
            'account': account,
          }),
          200,
        );
      });
    }

    Future<(WalletController, List<Uri>)> openSheet(
      WidgetTester tester, {
      DevServicesController? dev,
    }) async {
      final store = (await tester.runAsync(LocalStore.open))!;
      final wallet = WalletController(store)..load();
      final opened = <Uri>[];

      await tester.pumpWidget(
        appHarness(
          store: store,
          wallet: wallet,
          devServices: dev ?? DevServicesController(store),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TopUpSheet(
                      pollEvery: const Duration(seconds: 3),
                      openUrl: (url) async {
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
      return (wallet, opened);
    }

    /// Lets the scripted server's answers arrive without letting the clock
    /// run on. `pumpAndSettle` cannot be used while waiting: the spinner never
    /// settles, so it would advance time through every poll until the payment
    /// had already gone through.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    }

    Future<DevServicesController> devWith(
      WidgetTester tester,
      MockClient client,
    ) async {
      final store = (await tester.runAsync(LocalStore.open))!;
      final dev = DevServicesController(store, client: client);
      await tester.runAsync(() => dev.setUrl('localhost:8787'));
      return dev;
    }

    testWidgets('without a dev server it is the simulation, and says so', (
      tester,
    ) async {
      final (wallet, opened) = await openSheet(tester);

      expect(find.textContaining('No real payment is taken'), findsOneWidget);
      await tester.tap(find.text('Add Rs. 500'));
      await tester.pumpAndSettle();

      expect(wallet.balance, 500);
      expect(opened, isEmpty);
    });

    testWidgets('with Stripe, tokens land when Stripe says paid — not before', (
      tester,
    ) async {
      final log = <http.Request>[];
      final dev = await devWith(tester, stripeServer(paidAfter: 2, log: log));
      final (wallet, opened) = await openSheet(tester, dev: dev);

      expect(find.textContaining('Stripe test mode'), findsOneWidget);
      await tester.tap(find.text('Pay Rs. 1,000 with Stripe'));
      await settle(tester);

      expect(opened.single.host, 'checkout.stripe.com');
      expect(find.text('Waiting for Stripe'), findsOneWidget);
      final asked = log.firstWhere((r) => r.url.path == '/payments/checkout');
      expect(jsonDecode(asked.body), {'tokens': 1000, 'account': 'local-user'});

      // First look: not paid yet. Nothing moves.
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(wallet.balance, 0);
      expect(find.text('Waiting for Stripe'), findsOneWidget);

      // Second look: paid. The poll stops, so the sheet can close.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(wallet.balance, 1000);
      expect(wallet.hasCredited('cs_test_abc'), isTrue);
      expect(find.text('Waiting for Stripe'), findsNothing);
      expect(find.text('Rs. 1,000 added to your wallet.'), findsOneWidget);
    });

    testWidgets('credits what Stripe charged, not what was asked for', (
      tester,
    ) async {
      final dev = await devWith(
        tester,
        stripeServer(paidAfter: 1, tokens: 500),
      );
      final (wallet, _) = await openSheet(tester, dev: dev);

      await tester.tap(find.text('Pay Rs. 1,000 with Stripe'));
      await settle(tester);
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);

      expect(wallet.balance, 500);
    });

    testWidgets("a payment for somebody else's wallet is not credited here", (
      tester,
    ) async {
      final dev = await devWith(
        tester,
        stripeServer(paidAfter: 1, account: 'user-002'),
      );
      final (wallet, _) = await openSheet(tester, dev: dev);

      await tester.tap(find.text('Pay Rs. 1,000 with Stripe'));
      await settle(tester);
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);

      expect(wallet.balance, 0);
      expect(find.textContaining('does not match this wallet'), findsOneWidget);
    });

    testWidgets('an expired page says nothing was charged', (tester) async {
      final dev = await devWith(tester, stripeServer(status: 'expired'));
      final (wallet, _) = await openSheet(tester, dev: dev);

      await tester.tap(find.text('Pay Rs. 1,000 with Stripe'));
      await settle(tester);
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);

      expect(wallet.balance, 0);
      expect(
        find.text('That payment page expired. Nothing was charged.'),
        findsOneWidget,
      );
      expect(find.text('Pay Rs. 1,000 with Stripe'), findsOneWidget);
    });

    testWidgets('paying and giving up a second too soon still credits', (
      tester,
    ) async {
      // Paid by the first look — but the person taps "stop waiting" before
      // the first tick. The last look is what catches it.
      final dev = await devWith(tester, stripeServer(paidAfter: 1));
      final (wallet, _) = await openSheet(tester, dev: dev);

      await tester.tap(find.text('Pay Rs. 1,000 with Stripe'));
      await settle(tester);
      await tester.tap(find.text('Stop waiting'));
      await tester.pumpAndSettle();

      expect(wallet.balance, 1000);
    });

    testWidgets('stopping the wait stops asking', (tester) async {
      final log = <http.Request>[];
      final dev = await devWith(tester, stripeServer(paidAfter: 99, log: log));
      await openSheet(tester, dev: dev);

      await tester.tap(find.text('Pay Rs. 1,000 with Stripe'));
      await settle(tester);
      await tester.tap(find.text('Stop waiting'));
      await settle(tester);

      final before = log.length;
      await tester.pump(const Duration(seconds: 10));
      expect(log.length, before);
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
