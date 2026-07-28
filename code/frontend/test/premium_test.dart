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
          listing(radiusMetres: 8000),
          workerAt: islamabad,
          hirerAt: muzaffarabad,
        ),
        isFalse,
      );
      expect(
        rules.reaches(
          listing(radiusMetres: 200000),
          workerAt: islamabad,
          hirerAt: muzaffarabad,
        ),
        isTrue,
      );
    });

    test('remote work ignores it entirely', () {
      expect(
        rules.reaches(
          listing(radiusMetres: 1, remoteOnly: true),
          workerAt: islamabad,
          hirerAt: muzaffarabad,
        ),
        isTrue,
      );
    });

    test('an unknown position stands the radius down', () {
      // Same call the Mode A geofence makes: somebody who declined location
      // should lose sorting, not lose access.
      expect(
        rules.reaches(listing(), workerAt: islamabad, hirerAt: null),
        isTrue,
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
