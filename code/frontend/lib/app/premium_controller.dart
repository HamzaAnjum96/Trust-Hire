import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../features/premium/premium_rules.dart';
import '../models/account.dart';
import '../models/job.dart';
import '../models/job_tag.dart';
import '../models/premium.dart';
import '../services/local_store.dart';

/// Every directory listing, and which of them is yours.
///
/// One controller for both halves. A hirer browsing the directory and a worker
/// editing their own menu are reading and writing the same records, and
/// splitting them would mean keeping two copies of the same list in step —
/// with the price a hirer is about to be charged on one side of the split.
class PremiumController extends ChangeNotifier {
  PremiumController(
    this._store, {
    this.rules = const PremiumRules(),
    this.uuid = const Uuid(),
  });

  final LocalStore _store;
  final PremiumRules rules;

  @visibleForTesting
  final Uuid uuid;

  Map<String, DirectoryListing> _listings = <String, DirectoryListing>{};

  String _workerId = DemoAccounts.deviceId;

  /// Points the controller at another account. The listings themselves are
  /// shared — a directory everyone can see is the point — so only *whose*
  /// listing counts as mine changes.
  void setAccount(String id) {
    if (_workerId == id) return;
    _workerId = id;
    notifyListeners();
  }

  void load() {
    final raw = _store.readCollection(StoreKeys.directory) ?? const [];
    _listings = {
      for (final json in raw)
        (json['workerId'] as String): DirectoryListing.fromJson(json),
    };
    notifyListeners();
  }

  /// This account's listing, which always exists — a worker who has never
  /// subscribed still needs somewhere to put a service before they pay for it,
  /// and an empty draft is friendlier than a screen that asks for money first.
  DirectoryListing get mine =>
      _listings[_workerId] ?? DirectoryListing(workerId: _workerId);

  DirectoryListing? listingFor(String workerId) => _listings[workerId];

  bool get isPremium =>
      mine.subscription?.isActiveAt(DateTime.now()) ?? false;

  /// True when the subscription has run out but the listing is still there —
  /// the state Section 9's lapse handling describes, and the one worth naming
  /// on screen rather than showing as simply "not premium".
  bool get hasLapsed =>
      mine.subscription != null && !isPremium;

  /// The directory a hirer sees.
  List<DirectoryListing> directory({
    JobTag? tag,
    JobLocation? hirerAt,
    bool onlyWithinReach = true,
    DirectoryOrder order = DirectoryOrder.byName,
    String? query,
    Map<String, String> names = const <String, String>{},
    DateTime? now,
  }) => rules.directory(
    _listings.values,
    now: now ?? DateTime.now(),
    tag: tag,
    hirerAt: hirerAt,
    onlyWithinReach: onlyWithinReach,
    order: order,
    query: query,
    names: names,
  );

  /// How far a worker is from the hirer, for the card. Null when either end
  /// has not said where it is.
  double? distanceTo(DirectoryListing listing, {JobLocation? hirerAt}) =>
      rules.distanceFrom(listing, hirerAt: hirerAt);

  /// Every tag anybody in the directory actually offers, so the filter row
  /// never shows a category with nothing behind it.
  ///
  /// **Deliberately ignores the hirer's position and their search.** This
  /// feeds the chip row, and a chip row that empties as you type is a filter
  /// fighting the filter above it — the row should say what the directory
  /// holds, not what the current query left of it.
  Set<JobTag> get directoryTags => {
    for (final listing in directory(onlyWithinReach: false)) ...listing.tags,
  };

  /// Buys or extends premium. Simulated — Section 13a excludes real payment
  /// handling, and the screen that calls this says so in as many words.
  Future<Subscription> subscribe(SubscriptionPlan plan, {DateTime? at}) async {
    final now = at ?? DateTime.now();
    final renewed = rules.renew(mine.subscription, plan, now: now);

    await _save(mine.copyWith(subscription: renewed));
    return renewed;
  }

  Future<void> addService({
    required JobTag tag,
    required String title,
    required int priceRupees,
    String? description,
  }) async {
    final trimmed = description?.trim();

    await _save(
      mine.copyWith(
        services: [
          ...mine.services,
          ServiceOffering(
            id: uuid.v4(),
            tag: tag,
            title: title.trim(),
            priceRupees: priceRupees,
            description: (trimmed?.isEmpty ?? true) ? null : trimmed,
          ),
        ],
      ),
    );
  }

  Future<void> removeService(String serviceId) async {
    await _save(
      mine.copyWith(
        services: mine.services
            .where((service) => service.id != serviceId)
            .toList(growable: false),
      ),
    );
  }

  Future<void> addCredential({
    required CredentialKind kind,
    required String title,
    String? issuer,
    int? year,
  }) async {
    final trimmedIssuer = issuer?.trim();

    await _save(
      mine.copyWith(
        credentials: [
          ...mine.credentials,
          WorkerCredential(
            id: uuid.v4(),
            kind: kind,
            title: title.trim(),
            issuer: (trimmedIssuer?.isEmpty ?? true) ? null : trimmedIssuer,
            year: year,
          ),
        ],
      ),
    );
  }

  Future<void> removeCredential(String credentialId) async {
    await _save(
      mine.copyWith(
        credentials: mine.credentials
            .where((credential) => credential.id != credentialId)
            .toList(growable: false),
      ),
    );
  }

  Future<void> setServiceArea({
    double? radiusMetres,
    bool? remoteOnly,
    JobLocation? base,
  }) async {
    await _save(
      mine.copyWith(
        serviceRadiusMetres: radiusMetres,
        remoteOnly: remoteOnly,
        base: base,
      ),
    );
  }

  Future<void> setHeadline(String? headline) async {
    final trimmed = headline?.trim();
    await _save(
      mine.copyWith(
        headline: trimmed,
        clearHeadline: trimmed?.isEmpty ?? true,
      ),
    );
  }

  Future<void> _save(DirectoryListing listing) async {
    _listings = {..._listings, listing.workerId: listing};
    notifyListeners();

    await _store.writeCollection(
      StoreKeys.directory,
      _listings.values.map((l) => l.toJson()).toList(growable: false),
    );
  }
}
