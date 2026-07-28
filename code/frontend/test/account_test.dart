import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/account_controller.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/profile_controller.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/features/account/account_switcher.dart';
import 'package:trust_hire/features/jobs/saved_jobs_controller.dart';
import 'package:trust_hire/models/account.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/worker_profile.dart';
import 'package:trust_hire/services/local_store.dart';

import 'support/seed_facts.dart';
import 'support/surface.dart';

/// **The POC has no sign-in, and demo accounts are not one.**
///
/// They exist because every rule Phase 1 added — who may bid, who may edit,
/// who is charged commission, who may rate whom — is a rule about *two*
/// people, and until now a device could only ever be one of them. Half of the
/// behaviour was therefore unreachable: you could post a job or make an offer
/// on it, never both, and never see what the other side was looking at.
///
/// So these tests are about identity being a *choice* that everything else
/// follows: switch person, and ownership, the wallet, the trades and the
/// bookmarks all move with you.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const somewhere = JobLocation(latitude: 33.7104, longitude: 73.0551);

  Job job({String? postedBy, bool isLocal = false}) => Job(
    id: 'job-1',
    location: somewhere,
    createdAt: DateTime(2026, 7, 27),
    tags: const {JobTag.misc},
    postedBy: postedBy,
    isLocal: isLocal,
  );

  group('the roster', () {
    test('names the people the seed data actually contains', () async {
      // The roster duplicates five names out of the seed so the switcher can
      // be drawn before the seed loads. This is the check that keeps the
      // duplicate honest — regenerating the seed with different names should
      // fail here rather than silently mislabel somebody in the switcher.
      final users =
          (await SeedFacts.readJsonAsset('assets/seed/users.json')
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();

      final byId = {for (final user in users) user['id'] as String: user};

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final seeded = byId[account.id];
        expect(
          seeded,
          isNotNull,
          reason: '${account.id} is offered in the switcher but not seeded',
        );
        expect(seeded!['name'], account.name);
        expect(seeded['area'], account.area);
      }
    });

    test('every persona has jobs to show', () async {
      // A switcher that lands you on an empty "my postings" list looks like a
      // failed switch. Each persona is chosen for having posted work.
      final jobs =
          (await SeedFacts.readJsonAsset('assets/seed/jobs.json')
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        expect(
          jobs.where((job) => job['postedBy'] == account.id).length,
          greaterThan(0),
          reason: '${account.name} has nothing posted',
        );
      }
    });

    test('an unknown id falls back to the device account', () {
      // An id can outlive a roster edit. Being yourself again is a recoverable
      // outcome; failing to start is not.
      expect(DemoAccounts.byId('user-does-not-exist').isDevice, isTrue);
      expect(DemoAccounts.byId(null).isDevice, isTrue);
    });
  });

  group('who owns a job', () {
    test('the poster does, and nobody else', () {
      expect(job(postedBy: 'user-003').isPostedBy('user-003'), isTrue);
      expect(job(postedBy: 'user-003').isPostedBy('user-009'), isFalse);
      expect(job(postedBy: 'user-003').isPostedBy(DemoAccounts.deviceId), isFalse);
    });

    test('a job saved before demo accounts belongs to the device', () {
      // Everything already in somebody's browser storage was posted by the one
      // identity the app had. Without this it would belong to nobody after an
      // update: unowned, uneditable, and biddable by its own author.
      final legacy = job(isLocal: true);

      expect(legacy.postedBy, isNull);
      expect(legacy.isPostedBy(DemoAccounts.deviceId), isTrue);
      expect(legacy.isPostedBy('user-003'), isFalse);
    });

    test('a seeded job with no poster belongs to nobody', () {
      expect(job().isPostedBy(DemoAccounts.deviceId), isFalse);
    });
  });

  group('switching', () {
    test('is remembered across a restart', () async {
      final store = await LocalStore.open();
      final accounts = AccountController(store)..load();
      expect(accounts.active.isDevice, isTrue);

      await accounts.switchTo(DemoAccounts.roster[1]);

      final reopened = AccountController(store)..load();
      expect(reopened.activeId, DemoAccounts.roster[1].id);
    });

    test('gives each account its own wallet', () async {
      final store = await LocalStore.open();
      final wallet = WalletController(store)..load();

      await wallet.topUp(500);
      expect(wallet.balance, 500);

      wallet.setAccount('user-003');
      expect(
        wallet.balance,
        0,
        reason: 'a hirer should not inherit the worker\'s tokens',
      );

      // And back again — the first ledger was saved, not discarded.
      wallet.setAccount(DemoAccounts.deviceId);
      expect(wallet.balance, 500);
    });

    test('gives each account its own trades', () async {
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();

      await profile.toggleTag(JobTag.plumbing);
      expect(profile.tags, contains(JobTag.plumbing));

      profile.setAccount('user-003');
      expect(profile.tags, isNot(contains(JobTag.plumbing)));

      profile.setAccount(DemoAccounts.deviceId);
      expect(profile.tags, contains(JobTag.plumbing));
    });

    test('gives each account its own saved jobs', () async {
      final store = await LocalStore.open();
      final saved = SavedJobsController(store)..load();

      await saved.toggle('job-1');
      expect(saved.isSaved('job-1'), isTrue);

      saved.setAccount('user-003');
      expect(saved.isSaved('job-1'), isFalse);

      saved.setAccount(DemoAccounts.deviceId);
      expect(saved.isSaved('job-1'), isTrue);
    });

    test('leaves the device account on the keys it already used', () async {
      // The upgrade path. Anyone who used the app before the switcher existed
      // has a wallet, a role and a tag list under the unsuffixed keys; those
      // have to still be theirs afterwards.
      SharedPreferences.setMockInitialValues(<String, Object>{
        StoreKeys.role: 'hirer',
      });

      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();

      expect(profile.role, UserRole.hirer);
      expect(
        StoreKeys.forAccount(StoreKeys.role, DemoAccounts.deviceId),
        StoreKeys.role,
      );
    });

    test('resetting clears the per-account keys too', () async {
      final store = await LocalStore.open();
      final wallet = WalletController(store)..load();
      wallet.setAccount('user-003');
      await wallet.topUp(700);

      await store.clear();

      final reopened = WalletController(store)..setAccount('user-003');
      expect(reopened.balance, 0);
    });
  });

  group('the switcher', () {
    Future<void> pumpApp(WidgetTester tester) async {
      final store = await LocalStore.open();
      await (SettingsController(store)..load()).markIntroSeen();

      await tester.useCompactSurface();
      await tester.pumpWidget(TrustHireApp(store: store));

      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('says who you are on the map, and offers the others', (
      tester,
    ) async {
      await pumpApp(tester);

      // The map has no app bar, so the header carries the avatar. It is the
      // landing screen; a demonstration must not start on an unanswered
      // "who am I?".
      expect(find.byType(AccountAvatar), findsWidgets);

      await tester.tap(find.byType(AccountAvatar).first);
      await tester.pumpAndSettle();

      expect(find.text('Demo accounts'), findsOneWidget);
      expect(find.text('You'), findsWidgets);
      for (final account in DemoAccounts.roster.skip(1)) {
        expect(find.text(account.name!), findsOneWidget);
      }
    });

    testWidgets('switching moves the postings with you', (tester) async {
      await pumpApp(tester);

      // Hina Butt has four jobs in the seed; the device account has none.
      final hina = DemoAccounts.roster[1];

      await tester.tap(find.byType(AccountAvatar).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(hina.name!));
      await tester.pumpAndSettle();

      expect(find.text('You are now ${hina.name}'), findsOneWidget);

      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Posted · 4'), findsOneWidget);
    });

    testWidgets('and the profile follows', (tester) async {
      await pumpApp(tester);
      final usman = DemoAccounts.roster[2];

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('You'), findsWidgets);

      await tester.tap(find.byType(AccountCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text(usman.name!));
      await tester.pumpAndSettle();

      expect(find.text(usman.name!), findsWidgets);
      expect(find.text(usman.area!), findsWidgets);
    });
  });

  test('the same job is two different things to two people', () async {
    // The whole reason this exists. Not a widget assertion: the point is not
    // that two screens exist, it is that one job answers "is this mine?"
    // differently depending on who is holding the phone — and every screen
    // that branches on ownership is downstream of that one answer.
    final store = await LocalStore.open();
    final accounts = AccountController(store)..load();

    final mine = job(postedBy: DemoAccounts.deviceId);
    expect(mine.isPostedBy(accounts.activeId), isTrue);

    await accounts.switchTo(DemoAccounts.roster[1]);
    expect(mine.isPostedBy(accounts.activeId), isFalse);
  });
}
