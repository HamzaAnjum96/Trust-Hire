import 'job.dart' show JobLocation;
import 'job_tag.dart';

/// How long a subscription was bought for.
///
/// Two lengths and no more. Section 9 says "monthly/yearly"; a pricing table
/// with six tiers would be a business decision this POC is not in a position
/// to make, and every extra option is another thing to explain to somebody who
/// is deciding whether to spend money they may not have.
enum SubscriptionPlan {
  monthly(days: 30),
  yearly(days: 365);

  const SubscriptionPlan({required this.days});

  final int days;

  String get id => name;

  static SubscriptionPlan fromId(String? id) =>
      SubscriptionPlan.values.firstWhere(
        (plan) => plan.id == id,
        orElse: () => monthly,
      );
}

/// A worker's paid presence in the directory.
///
/// Stored as a start and an end rather than as a boolean, because "premium"
/// is a fact about a moment: Section 9's lapse handling turns on whether the
/// subscription is live *now*, and a flag somebody has to remember to clear
/// is a flag that will still be set a year after the money stopped.
class Subscription {
  const Subscription({
    required this.plan,
    required this.startedAt,
    required this.expiresAt,
  });

  final SubscriptionPlan plan;
  final DateTime startedAt;
  final DateTime expiresAt;

  bool isActiveAt(DateTime now) => now.isBefore(expiresAt);

  /// Whole days left, floored, and never negative.
  int daysLeftAt(DateTime now) {
    final left = expiresAt.difference(now).inDays;
    return left < 0 ? 0 : left;
  }

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    plan: SubscriptionPlan.fromId(json['plan'] as String?),
    startedAt: DateTime.parse(json['startedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'plan': plan.id,
    'startedAt': startedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };
}

/// One thing a premium worker does, at one price.
///
/// **The price is fixed and the hirer sees it before booking.** That is the
/// whole difference between Mode B and Mode A: no starting fare, no offers, no
/// negotiation. A professional who charges Rs. 1,500 for a consultation should
/// not have to defend that number to every enquiry.
class ServiceOffering {
  const ServiceOffering({
    required this.id,
    required this.tag,
    required this.title,
    required this.priceRupees,
    this.description,
  });

  final String id;
  final JobTag tag;
  final String title;

  /// Whole rupees. The same rule as every other fare in the app — the
  /// audience does not think about a job in paisa.
  final int priceRupees;

  final String? description;

  ServiceOffering copyWith({
    JobTag? tag,
    String? title,
    int? priceRupees,
    String? description,
    bool clearDescription = false,
  }) => ServiceOffering(
    id: id,
    tag: tag ?? this.tag,
    title: title ?? this.title,
    priceRupees: priceRupees ?? this.priceRupees,
    description: clearDescription ? null : (description ?? this.description),
  );

  factory ServiceOffering.fromJson(Map<String, dynamic> json) =>
      ServiceOffering(
        id: json['id'] as String,
        tag: JobTag.fromId(json['tag'] as String?) ?? JobTag.misc,
        title: json['title'] as String,
        priceRupees: (json['priceRupees'] as num).round(),
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'tag': tag.id,
    'title': title,
    'priceRupees': priceRupees,
    'description': description,
  };
}

/// What kind of thing a worker is claiming.
///
/// Kept as a short closed list so the showcase reads as a record rather than
/// as free text — and so an admin dispute in P1-7 has something to sort by.
enum CredentialKind {
  qualification,
  certification,
  experience,
  membership;

  String get id => name;

  static CredentialKind fromId(String? id) => CredentialKind.values.firstWhere(
    (kind) => kind.id == id,
    orElse: () => qualification,
  );
}

/// A degree, a certificate, years in a trade.
///
/// **Self-declared, and the app says so wherever these appear.** Section 2
/// verifies a CNIC and a phone number; it does not verify a degree, and
/// showing an unchecked claim without that word next to it would be the app
/// vouching for something nobody checked.
class WorkerCredential {
  const WorkerCredential({
    required this.id,
    required this.kind,
    required this.title,
    this.issuer,
    this.year,
  });

  final String id;
  final CredentialKind kind;
  final String title;
  final String? issuer;
  final int? year;

  factory WorkerCredential.fromJson(Map<String, dynamic> json) =>
      WorkerCredential(
        id: json['id'] as String,
        kind: CredentialKind.fromId(json['kind'] as String?),
        title: json['title'] as String,
        issuer: json['issuer'] as String?,
        year: (json['year'] as num?)?.round(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind.id,
    'title': title,
    'issuer': issuer,
    'year': year,
  };
}

/// Everything one worker puts in the directory.
///
/// One object rather than four stores, because the four are meaningless apart:
/// a service menu nobody can find, a radius around nothing, credentials
/// attached to no offer. It is also what makes the lapse rule a single check —
/// [PremiumRules.appearsInDirectory] looks at one thing.
class DirectoryListing {
  const DirectoryListing({
    required this.workerId,
    this.subscription,
    this.services = const <ServiceOffering>[],
    this.credentials = const <WorkerCredential>[],
    this.serviceRadiusMetres = defaultServiceRadiusMetres,
    this.remoteOnly = false,
    this.headline,
    this.base,
  });

  /// Section 9 gives no number. 10 km is the middle of the Mode A geofence
  /// range and a distance a barber with a motorbike would recognise; every
  /// worker can change it, which is the part the spec does insist on.
  static const defaultServiceRadiusMetres = 10000.0;

  final String workerId;

  /// Null when this worker has never subscribed. Lapsed subscriptions are
  /// kept rather than deleted — Section 9's lapse handling is about future
  /// searches only, and a worker who resubscribes should see their own
  /// history rather than a blank slate.
  final Subscription? subscription;

  final List<ServiceOffering> services;
  final List<WorkerCredential> credentials;

  /// How far this worker will travel. **Separate from the job-centered
  /// geofence in Mode A**, and deliberately so: in Mode A a hirer decides how
  /// far to cast for their job, and in Mode B a worker decides how far they
  /// will go. The two answer different questions and neither substitutes.
  final double serviceRadiusMetres;

  /// For work that needs no travel at all — a lawyer taking calls. The radius
  /// stops meaning anything when this is set.
  final bool remoteOnly;

  /// One line under the name. Optional, like everything else a person is
  /// asked to write.
  final String? headline;

  /// Where [serviceRadiusMetres] is measured *from* — roughly, the worker's
  /// own area.
  ///
  /// **Without this the radius was decorative.** A worker could set "I travel
  /// 12 km" on their listing and the directory would still show them to a
  /// hirer four hundred kilometres away, because nothing knew 12 km from
  /// where. [PremiumRules.reaches] existed, and was tested, and had no callers
  /// for exactly this reason.
  ///
  /// Approximate on purpose, and to the same standard as everything else
  /// positional in this app: an area centre, not an address. A worker is
  /// advertising, not publishing where they sleep.
  ///
  /// Null for a listing that has never said — treated as reaching everybody,
  /// because a worker who has not answered should lose sorting rather than
  /// lose the shelf they paid for.
  final JobLocation? base;

  bool get hasServices => services.isNotEmpty;

  Set<JobTag> get tags => services.map((service) => service.tag).toSet();

  ServiceOffering? serviceById(String id) {
    for (final service in services) {
      if (service.id == id) return service;
    }
    return null;
  }

  /// The cheapest thing on the menu, for the directory card.
  int? get fromPrice => services.isEmpty
      ? null
      : services.map((s) => s.priceRupees).reduce((a, b) => a < b ? a : b);

  DirectoryListing copyWith({
    Subscription? subscription,
    bool clearSubscription = false,
    List<ServiceOffering>? services,
    List<WorkerCredential>? credentials,
    double? serviceRadiusMetres,
    bool? remoteOnly,
    String? headline,
    bool clearHeadline = false,
    JobLocation? base,
  }) => DirectoryListing(
    workerId: workerId,
    subscription: clearSubscription
        ? null
        : (subscription ?? this.subscription),
    services: services ?? this.services,
    credentials: credentials ?? this.credentials,
    serviceRadiusMetres: serviceRadiusMetres ?? this.serviceRadiusMetres,
    remoteOnly: remoteOnly ?? this.remoteOnly,
    headline: clearHeadline ? null : (headline ?? this.headline),
    base: base ?? this.base,
  );

  factory DirectoryListing.fromJson(Map<String, dynamic> json) =>
      DirectoryListing(
        workerId: json['workerId'] as String,
        subscription: json['subscription'] == null
            ? null
            : Subscription.fromJson(
                json['subscription'] as Map<String, dynamic>,
              ),
        services: (json['services'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ServiceOffering.fromJson)
            .toList(growable: false),
        credentials: (json['credentials'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(WorkerCredential.fromJson)
            .toList(growable: false),
        serviceRadiusMetres:
            (json['serviceRadiusMetres'] as num?)?.toDouble() ??
            defaultServiceRadiusMetres,
        remoteOnly: json['remoteOnly'] as bool? ?? false,
        headline: json['headline'] as String?,
        base: json['base'] == null
            ? null
            : JobLocation.fromJson(json['base'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'workerId': workerId,
    'subscription': subscription?.toJson(),
    'services': services.map((s) => s.toJson()).toList(),
    'credentials': credentials.map((c) => c.toJson()).toList(),
    'serviceRadiusMetres': serviceRadiusMetres,
    'remoteOnly': remoteOnly,
    'headline': headline,
    'base': base?.toJson(),
  };
}
