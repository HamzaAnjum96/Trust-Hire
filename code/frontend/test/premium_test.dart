import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/premium_controller.dart';
import 'package:trust_hire/features/feed/job_visibility.dart';
import 'package:trust_hire/features/lifecycle/job_lifecycle.dart';
import 'package:trust_hire/features/premium/premium_rules.dart';
import 'package:trust_hire/features/wallet/wallet_rules.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/premium.dart';
import 'package:trust_hire/models/worker_profile.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

/// Section 9 — Mode B, the directory, and the money that makes it work.
///
/// Two things here are load-bearing and neither is the browsing.
///
/// The first is the **discount**, because it is the platform's answer to
/// leakage: if booking in the app is not cheaper than ringing the same worker
/// directly, the directory is a free introduction service and everybody stops
/// paying. The spec contradicts itself about who funds it, and the resolution
/// is tested here rather than left in a comment.
///
/// The second is that a booking reaches **one person**. A "direct request"
/// that quietly broadcast would hand a hirer's chosen worker's job to
/// everybody, which is the opposite of what they asked for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const rules = PremiumRules();
  final now = DateTime(2026, 7, 27, 10);
  const islamabad = JobLocation(latitude: 33.7104, longitude: 73.0551);
  const muzaffarabad = JobLocation(latitude: 34.3700, longitude: 73.4711);

  ServiceOffering service({int price = 3000, JobTag tag = JobTag.beauty}) =>
      ServiceOffering(
        id: 'svc-1',
        tag: tag,
        title: 'Home haircut',
        priceRupees: price,
      );

  DirectoryListing listing({
    int? daysLeft = 30,
    List<ServiceOffering>? services,
    double radiusMetres = 10000,
    bool remoteOnly = false,
    JobLocation? base,
  }) => DirectoryListing(
    workerId: 'w1',
    subscription: daysLeft == null
        ? null
        : Subscription(
            plan: SubscriptionPlan.monthly,
            startedAt: now.subtract(const Duration(days: 30)),
            expiresAt: now.add(Duration(days: daysLeft)),
          ),
    services: services ?? [service()],
    serviceRadiusMetres: radiusMetres,
    remoteOnly: remoteOnly,
    base: base,
  );

  group('the hirer discount', () {
    test('takes 2.5% off, in the hirer\'s favour', () {
      expect(rules.priceForHirer(3000), 2925);
      expect(rules.discountOn(3000), 75);

      // Rounds down, like the commission, so the fraction falls to the person
      // being charged rather than to the platform.
      expect(rules.discountOn(1010), 25);
      expect(rules.priceForHirer(1010), 985);
    });

    test('leaves the worker exactly as well off as Mode A', () {
      // The whole reason the commission is halved rather than kept at 5%.
      // Section 9 says the platform splits *its own* take and that "the
      // worker's cost is unaffected"; this is that sentence as arithmetic.
      const walletRules = WalletRules();
      const listed = 3000;

      final modeANet = listed - walletRules.commissionOn(listed);
      final modeBNet =
          rules.priceForHirer(listed) - rules.commissionOnBooking(listed);

      expect(modeANet, 2850);
      expect(modeBNet, modeANet);
    });

    test('and costs the platform half its usual take', () {
      const listed = 3000;
      const walletRules = WalletRules();

      expect(
        rules.commissionOnBooking(listed) * 2,
        walletRules.commissionOn(listed),
      );
    });

    test('the wallet charges the booking rate on a booked job', () {
      const walletRules = WalletRules();

      final booked = Job(
        id: 'j1',
        location: islamabad,
        createdAt: now,
        tags: const {JobTag.beauty},
        listedFare: 3000,
        agreedFare: 2925,
        bookedWorkerId: 'w1',
      );
      final bid = Job(
        id: 'j2',
        location: islamabad,
        createdAt: now,
        tags: const {JobTag.beauty},
        agreedFare: 3000,
      );

      expect(walletRules.commissionFor(booked), 75);
      expect(walletRules.commissionFor(bid), 150);
    });
  });

  group('who is in the directory', () {
    test('somebody who is paying and has something to book', () {
      expect(rules.appearsInDirectory(listing(), now: now), isTrue);
    });

    test('not somebody who never subscribed', () {
      expect(rules.appearsInDirectory(listing(daysLeft: null), now: now),
          isFalse);
    });

    test('not somebody whose subscription ran out', () {
      // Section 9's lapse handling: future searches only.
      expect(
        rules.appearsInDirectory(listing(daysLeft: -1), now: now),
        isFalse,
      );
    });

    test('not somebody with an empty menu', () {
      // A name with nothing to book is a dead end for the hirer and a bad
      // first impression for the worker.
      expect(
        rules.appearsInDirectory(listing(services: const []), now: now),
        isFalse,
      );
    });

    test('a lapse touches nothing except being found', () {
      // The two things the spec is explicit about, as one test: a job already
      // booked runs to completion, and Mode A bidding is untouched. Neither
      // asks whether the worker is in the directory, which is the point.
      final lapsed = listing(daysLeft: -30);
      const lifecycle = JobLifecycle();

      final booked = Job(
        id: 'j1',
        location: islamabad,
        createdAt: now,
        tags: const {JobTag.beauty},
        status: JobStatus.inProgress,
        bookedWorkerId: 'w1',
        acceptedWorkerId: 'w1',
        listedFare: 3000,
        agreedFare: 2925,
      );

      expect(rules.appearsInDirectory(lapsed, now: now), isFalse);
      expect(
        lifecycle.actionsFor(booked, role: JobRole.worker),
        isNotEmpty,
        reason: 'a job in progress must not stop because a listing lapsed',
      );
    });
  });

  group('how far a worker will travel', () {
    test('their own radius, not the job\'s', () {
      // Section 9 is explicit that this is "a separate mechanism from the
      // job-centered geofence in Mode A". In Mode A the hirer decides how far
      // to cast; here the worker decides how far to go.
      expect(
        rules.reaches(
          listing(radiusMetres: 8000, base: islamabad),
          hirerAt: muzaffarabad,
        ),
        isFalse,
      );
      expect(
        rules.reaches(
          listing(radiusMetres: 200000, base: islamabad),
          hirerAt: muzaffarabad,
        ),
        isTrue,
      );
    });

    test('remote work ignores it entirely', () {
      expect(
        rules.reaches(
          listing(radiusMetres: 1, remoteOnly: true, base: islamabad),
          hirerAt: muzaffarabad,
        ),
        isTrue,
      );
    });

    test('an unknown position stands the radius down', () {
      // Same call the Mode A geofence makes: somebody who declined location
      // should lose sorting, not lose access.
      expect(
        rules.reaches(listing(base: islamabad), hirerAt: null),
        isTrue,
      );

      // And the other way round: a worker who has never said where they are
      // keeps the shelf they paid for.
      expect(
        rules.reaches(listing(), hirerAt: muzaffarabad),
        isTrue,
        reason: 'a listing with no base must not vanish from the directory',
      );
    });
  });

  group('the directory a hirer actually sees', () {
    ServiceOffering named(String id, String title, int price, JobTag tag) =>
        ServiceOffering(id: id, tag: tag, title: title, priceRupees: price);

    DirectoryListing at(
      String id, {
      JobLocation? base,
      double radiusMetres = 10000,
      bool remoteOnly = false,
      List<ServiceOffering>? services,
      String? headline,
    }) => DirectoryListing(
      workerId: id,
      subscription: Subscription(
        plan: SubscriptionPlan.monthly,
        startedAt: now.subtract(const Duration(days: 30)),
        expiresAt: now.add(const Duration(days: 30)),
      ),
      services: services ?? [service()],
      serviceRadiusMetres: radiusMetres,
      remoteOnly: remoteOnly,
      headline: headline,
      base: base,
    );

    // Islamabad and Muzaffarabad are about 75 km apart.
    final near = at('near', base: islamabad, radiusMetres: 100000);
    final far = at('far', base: islamabad, radiusMetres: 8000);
    final remote = at('remote', base: islamabad, remoteOnly: true);

    test('leaves out the people who would not come', () {
      // **The bug this closes.** `reaches` was written and tested when Mode B
      // was built, and then had no caller for two sprints, because no listing
      // recorded where its worker was. A barber in Karachi appeared to a
      // hirer in Peshawar with "travels up to 10 km" written underneath.
      final shown = rules.directory(
        [near, far, remote],
        now: now,
        hirerAt: muzaffarabad,
      );

      expect(
        shown.map((l) => l.workerId),
        ['near', 'remote'],
        reason: 'somebody who travels 8 km cannot reach a hirer 75 km away',
      );
    });

    test('but shows them when the hirer asks to see everyone', () {
      final shown = rules.directory(
        [near, far, remote],
        now: now,
        hirerAt: muzaffarabad,
        onlyWithinReach: false,
      );

      expect(shown, hasLength(3));
    });

    test('a hirer who declined location loses sorting, not access', () {
      // The same call the Mode A geofence makes. Emptying the directory would
      // punish the permission refusal rather than work around it.
      expect(
        rules.directory([near, far, remote], now: now, hirerAt: null),
        hasLength(3),
      );
    });

    test('and so does a worker who never said where they are', () {
      final unplaced = at('unplaced', radiusMetres: 1);

      expect(
        rules.directory([unplaced], now: now, hirerAt: muzaffarabad),
        hasLength(1),
        reason: 'a listing with no base must keep the shelf it paid for',
      );
    });

    test('search reaches the name, the headline and the menu', () {
      final byHeadline = at('a', headline: 'Property and family matters');
      final byService = at(
        'b',
        services: [named('s1', 'Kitchen deep clean', 2500, JobTag.cleaning)],
      );
      final byName = at('c');
      final names = {'c': 'Sadia Iqbal'};

      List<String> found(String query) => rules
          .directory(
            [byHeadline, byService, byName],
            now: now,
            query: query,
            names: names,
          )
          .map((l) => l.workerId)
          .toList();

      expect(found('property'), ['a'], reason: 'the headline');
      expect(found('kitchen'), ['b'], reason: 'a service title');
      expect(found('sadia'), ['c'], reason: "the worker's name");
      expect(found('  KITCHEN  '), ['b'], reason: 'trimmed and case-folded');
      expect(found(''), hasLength(3), reason: 'an empty query is not a filter');
    });

    test('the default order is not one the platform could sell', () {
      // Cheapest first would teach workers to undercut each other, and
      // "featured" would charge twice for the same shelf. The default is
      // whatever order the caller supplied.
      final cheap = at(
        'cheap',
        services: [named('s1', 'A', 500, JobTag.beauty)],
      );
      final dear = at('dear', services: [named('s2', 'B', 9000, JobTag.beauty)]);

      expect(
        rules.directory([dear, cheap], now: now).map((l) => l.workerId),
        ['dear', 'cheap'],
        reason: 'the input order survived, so nothing re-ranked it',
      );
    });

    test('but a hirer may ask for one', () {
      final cheap = at(
        'cheap',
        services: [named('s1', 'A', 500, JobTag.beauty)],
      );
      final dear = at('dear', services: [named('s2', 'B', 9000, JobTag.beauty)]);
      final noMenu = at('noMenu', services: []);

      expect(
        rules
            .directory(
              [dear, noMenu, cheap],
              now: now,
              order: DirectoryOrder.byPrice,
            )
            .map((l) => l.workerId),
        ['cheap', 'dear'],
        reason: 'a listing with no menu has no price, and sorts out entirely '
            'because an empty menu keeps it out of the directory',
      );
    });

    test('nearest first puts the unplaceable last, never first', () {
      // Unknown is not near. Sorting a worker with no base to the top would
      // make the label a lie in exactly the case the hirer cannot check.
      final close = at('close', base: muzaffarabad, radiusMetres: 100000);
      final distant = at('distant', base: islamabad, radiusMetres: 100000);
      final unplaced = at('unplaced', radiusMetres: 100000);

      expect(
        rules
            .directory(
              [unplaced, distant, close],
              now: now,
              hirerAt: muzaffarabad,
              order: DirectoryOrder.byDistance,
            )
            .map((l) => l.workerId),
        ['close', 'distant', 'unplaced'],
      );
    });
  });

  group('booking', () {
    test('is refused against a listing that has lapsed', () {
      // The price and the radius were part of a live offer. Honouring a stale
      // screen would hold a worker to terms they have stopped offering.
      expect(
        rules.canBook(listing(daysLeft: -1), service: service(), now: now),
        isFalse,
      );
    });

    test('is refused for a service that has been taken down', () {
      expect(
        rules.canBook(
          listing(),
          service: service().copyWith(title: 'gone'),
          now: now,
        ),
        isTrue,
        reason: 'the same id is still on the menu',
      );

      expect(
        rules.canBook(
          listing(services: const []),
          service: service(),
          now: now,
        ),
        isFalse,
      );
    });

    test('reaches the one worker it was addressed to, and nobody else', () {
      // Section 9: "not broadcast". The tag rule and the geofence are both
      // bypassed for the worker it is for — they set their own radius when
      // they listed — and neither can let it through to anybody else.
      const visibility = JobVisibility();

      final booking = Job(
        id: 'j1',
        // Deliberately a tag the worker below does not hold, and far away.
        location: muzaffarabad,
        createdAt: now,
        tags: const {JobTag.beauty},
        bookedWorkerId: 'w1',
      );

      expect(
        visibility.isVisibleTo(
          booking,
          worker: WorkerProfile(userId: 'w1'),
          from: islamabad,
        ),
        isTrue,
      );
      expect(
        visibility.isVisibleTo(
          booking,
          // Somebody who does hold the tag, standing next to it.
          worker: WorkerProfile(userId: 'w2', tags: const {JobTag.beauty}),
          from: muzaffarabad,
        ),
        isFalse,
      );
    });

    test('the booked worker can accept or decline, and nothing else', () {
      const lifecycle = JobLifecycle();

      final booking = Job(
        id: 'j1',
        location: islamabad,
        createdAt: now,
        tags: const {JobTag.beauty},
        bookedWorkerId: 'w1',
        listedFare: 3000,
        agreedFare: 2925,
      );

      expect(lifecycle.roleFor(booking, viewerId: 'w1'), JobRole.worker);
      expect(
        lifecycle.actionsFor(booking, role: JobRole.worker),
        const [JobAction.acceptBooking, JobAction.declineBooking],
      );
      // The hirer can withdraw it and nothing else until it is answered.
      expect(
        lifecycle.actionsFor(booking, role: JobRole.hirer),
        const [JobAction.cancel],
      );
    });

    test('accepting records who accepted it, at the price already agreed', () {
      final booking = Job(
        id: 'j1',
        location: islamabad,
        createdAt: now,
        tags: const {JobTag.beauty},
        bookedWorkerId: 'w1',
        listedFare: 3000,
        agreedFare: 2925,
      );

      final taken = booking.withBookingAccepted();

      expect(taken.status, JobStatus.accepted);
      expect(taken.acceptedWorkerId, 'w1');
      expect(
        taken.agreedFare,
        2925,
        reason: 'Mode B is not negotiated; the price was fixed at booking',
      );
      expect(taken.hirerSaving, 75);
    });

    test('declining is not walking away from work', () {
      // It becomes cancelled rather than open — the hirer chose one person,
      // and reverting to the map would broadcast what they asked not to
      // broadcast. The wallet penalty is skipped, which is tested where the
      // penalty lives; here it is enough that the two actions are distinct.
      const lifecycle = JobLifecycle();

      final booking = Job(
        id: 'j1',
        location: islamabad,
        createdAt: now,
        tags: const {JobTag.beauty},
        bookedWorkerId: 'w1',
      );

      expect(
        lifecycle.resultOf(
          JobAction.declineBooking,
          job: booking,
          role: JobRole.worker,
        ),
        JobStatus.cancelled,
      );
      expect(JobAction.declineBooking, isNot(JobAction.cancel));
    });

    test('a booking does not expire on the map\'s clock', () {
      // Seven days of nobody bidding means a job nobody wants. Seven days of a
      // booking sitting unanswered means one person has not opened the app,
      // and cancelling it for them would be the platform making their excuses.
      const lifecycle = JobLifecycle();

      final old = Job(
        id: 'j1',
        location: islamabad,
        createdAt: now.subtract(const Duration(days: 30)),
        tags: const {JobTag.beauty},
        bookedWorkerId: 'w1',
      );

      expect(lifecycle.hasExpired(old, now: now), isFalse);
    });
  });

  group('the subscription', () {
    test('renewing early adds to what is left rather than restarting it', () {
      final existing = rules.start(SubscriptionPlan.monthly, now: now);
      final renewed = rules.renew(
        existing,
        SubscriptionPlan.monthly,
        now: now.add(const Duration(days: 10)),
      );

      expect(
        renewed.expiresAt,
        existing.expiresAt.add(const Duration(days: 30)),
        reason: 'renewing early must never cost a worker days',
      );
    });

    test('renewing after a lapse starts from today', () {
      final lapsed = Subscription(
        plan: SubscriptionPlan.monthly,
        startedAt: now.subtract(const Duration(days: 90)),
        expiresAt: now.subtract(const Duration(days: 30)),
      );

      final renewed = rules.renew(lapsed, SubscriptionPlan.monthly, now: now);
      expect(renewed.expiresAt, now.add(const Duration(days: 30)));
    });

    test('is stored, and read back as live or lapsed', () async {
      final store = await LocalStore.open();
      final premium = PremiumController(store)..load();

      expect(premium.isPremium, isFalse);
      await premium.subscribe(SubscriptionPlan.yearly);
      expect(premium.isPremium, isTrue);

      final reopened = PremiumController(store)..load();
      expect(reopened.isPremium, isTrue);
    });
  });

  group('a worker setting their own service area', () {
    test('the base is stored, and it narrows who can see them', () async {
      // The seed ships a base for everybody; a listing somebody creates in the
      // app would have none, so the radius they pick would do nothing. This is
      // the path a real worker takes.
      final store = await LocalStore.open();
      final premium = PremiumController(store)..load();

      await premium.setServiceArea(radiusMetres: 8000, base: islamabad);

      final reopened = PremiumController(store)..load();
      expect(reopened.mine.base, islamabad, reason: 'it did not survive a restart');
      expect(reopened.mine.serviceRadiusMetres, 8000);

      expect(
        rules.reaches(reopened.mine, hirerAt: muzaffarabad),
        isFalse,
        reason: 'the radius they picked must now exclude somebody',
      );
    });

    test('changing the radius later does not lose the base', () async {
      // `setServiceArea` takes three optional arguments and is called with one
      // at a time from three different controls on the screen. A copyWith that
      // treated the missing ones as "clear" would wipe the base every time
      // somebody tapped a distance chip.
      final store = await LocalStore.open();
      final premium = PremiumController(store)..load();

      await premium.setServiceArea(base: islamabad);
      await premium.setServiceArea(radiusMetres: 20000);

      expect(premium.mine.base, islamabad);
      expect(premium.mine.serviceRadiusMetres, 20000);
    });
  });

  group('the seeded directory', () {
    Future<PremiumController> seeded() async {
      final store = await LocalStore.open();
      await JobRepository(store, MediaStore(store)).ensureSeeded();
      return PremiumController(store)..load();
    }

    test('has people in it, across several kinds of work', () async {
      final premium = await seeded();
      final directory = premium.directory();

      expect(directory.length, greaterThan(4));
      expect(premium.directoryTags.length, greaterThan(4));
    });

    test('everybody who travels says where they travel from', () async {
      // The radius is meaningless without it, and a listing that claims
      // "travels up to 12 km" from nowhere in particular is worse than one
      // that claims nothing. The generator refuses to emit one; this is the
      // check that the seed on disk actually came from that generator.
      final premium = await seeded();

      for (final listing in premium.directory(onlyWithinReach: false)) {
        if (listing.remoteOnly) continue;
        expect(
          listing.base,
          isNotNull,
          reason: '${listing.workerId} has a service radius and no base',
        );
      }
    });

    test('and that place is inside Pakistan', () async {
      // Cheap, and it catches the one mistake this kind of generator actually
      // makes: latitude and longitude the wrong way round. Swapped, every
      // base lands in the Indian Ocean or western China, every distance is
      // wrong by a thousand kilometres, and the directory still renders
      // perfectly.
      final premium = await seeded();

      for (final listing in premium.directory(onlyWithinReach: false)) {
        final base = listing.base;
        if (base == null) continue;

        expect(
          base.latitude,
          inInclusiveRange(23.5, 37.1),
          reason: '${listing.workerId} is not at a Pakistani latitude',
        );
        expect(
          base.longitude,
          inInclusiveRange(60.8, 77.9),
          reason: '${listing.workerId} is not at a Pakistani longitude',
        );
      }
    });

    test('everybody listed has a price on everything', () async {
      final premium = await seeded();

      for (final listing in premium.directory()) {
        expect(listing.services, isNotEmpty, reason: listing.workerId);
        for (final service in listing.services) {
          expect(service.priceRupees, greaterThan(0), reason: service.id);
        }
      }
    });

    test('and one of them has lapsed, so the state is reachable', () async {
      // Otherwise nobody can see what Section 9's lapse handling looks like
      // without waiting a month.
      final store = await LocalStore.open();
      await JobRepository(store, MediaStore(store)).ensureSeeded();

      final all = (store.readCollection(StoreKeys.directory) ?? const [])
          .map(DirectoryListing.fromJson)
          .toList();
      final premium = PremiumController(store)..load();

      final lapsed = all.length - premium.directory().length;
      expect(lapsed, greaterThan(0));
    });
  });
}
