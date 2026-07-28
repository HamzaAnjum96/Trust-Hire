/// What somebody submitted, and what the automated checks made of it.
///
/// Mirrors the `verifications` table in `code/backend/migrations/`, one row per
/// account — deliberately, because the worker's submission and the admin's view
/// of it have to be the same record. Two copies would disagree the first time
/// somebody re-submitted, and the one an approval decision was made on would be
/// whichever the screen happened to read.
///
/// **These are signals, not identity.** Section 13 rules out any live NADRA
/// lookup, so the strongest claim available is that a number is the right shape
/// and that a phone answered a code. The field names say `plausible` and
/// `matches` rather than `verified` for exactly that reason, and every screen
/// showing them repeats it.
class Verification {
  const Verification({
    this.cnicMasked,
    this.cnicName,
    this.cnicDateOfBirth,
    this.cnicPlausible = false,
    this.cnicSubmittedAt,
    this.phone,
    this.phoneVerifiedAt,
    this.simNameMatches = true,
  });

  /// `*****-*****45-6`. **Never the whole number** — see
  /// `VerificationRules.mask`, which is the only thing that produces this, and
  /// the check constraint of the same name in the schema.
  final String? cnicMasked;

  /// The name printed on the card. Section 2 asks the automated check to
  /// confirm "name/DOB present", which is what this and [cnicDateOfBirth] are.
  final String? cnicName;
  final DateTime? cnicDateOfBirth;

  /// The number is the right shape and the card carries a name and a date of
  /// birth. An automated check, not a lookup.
  final bool cnicPlausible;

  /// When the photo was submitted. Null means nothing was.
  ///
  /// **Not** that anybody has looked at it: Section 2 is explicit that the
  /// photo "sits unreviewed unless a dispute is raised later".
  final DateTime? cnicSubmittedAt;

  /// Normalised to `+92...`, so the same phone typed four ways is one number.
  final String? phone;

  /// When a code sent to [phone] was answered correctly.
  final DateTime? phoneVerifiedAt;

  /// False when the SIM's registered name does not look like the name on the
  /// card.
  ///
  /// **A flag for review, never an auto-rejection.** Section 2 is explicit
  /// that false positives are expected — a worker on a family member's SIM is
  /// the ordinary case, not the fraud case — and the loophole it is aimed at
  /// is re-registering on a fresh Rs. 100 SIM after a ban.
  final bool simNameMatches;

  bool get cnicOnFile => cnicSubmittedAt != null;
  bool get phoneVerified => phoneVerifiedAt != null;
  bool get isFlagged => !simNameMatches;

  /// Everything Section 2 asks for is in. Not the same as being approved —
  /// that is a person's decision, and it is [AccountReview.status].
  bool get isComplete => cnicOnFile && cnicPlausible && phoneVerified;

  /// Nothing submitted at all. What a new account looks like.
  bool get isEmpty => !cnicOnFile && phone == null;

  /// How many of the three steps are done, for a progress line that does not
  /// have to enumerate them.
  int get stepsDone =>
      (cnicOnFile ? 1 : 0) + (cnicPlausible ? 1 : 0) + (phoneVerified ? 1 : 0);

  static const steps = 3;

  Verification withCnic({
    required String masked,
    required String name,
    DateTime? dateOfBirth,
    required bool plausible,
    required DateTime at,
    required bool simNameMatches,
  }) => Verification(
    cnicMasked: masked,
    cnicName: name,
    cnicDateOfBirth: dateOfBirth,
    cnicPlausible: plausible,
    cnicSubmittedAt: at,
    phone: phone,
    phoneVerifiedAt: phoneVerifiedAt,
    simNameMatches: simNameMatches,
  );

  /// A new number is a new claim. Confirming one phone says nothing about the
  /// next, so the verified date goes with the number it belonged to — the
  /// alternative is a "verified" tick sitting beside a number nobody has ever
  /// sent anything to.
  Verification withPhone(String? normalised) => Verification(
    cnicMasked: cnicMasked,
    cnicName: cnicName,
    cnicDateOfBirth: cnicDateOfBirth,
    cnicPlausible: cnicPlausible,
    cnicSubmittedAt: cnicSubmittedAt,
    phone: normalised,
    phoneVerifiedAt: normalised == phone ? phoneVerifiedAt : null,
    simNameMatches: simNameMatches,
  );

  Verification withPhoneConfirmed(DateTime at) => Verification(
    cnicMasked: cnicMasked,
    cnicName: cnicName,
    cnicDateOfBirth: cnicDateOfBirth,
    cnicPlausible: cnicPlausible,
    cnicSubmittedAt: cnicSubmittedAt,
    phone: phone,
    phoneVerifiedAt: at,
    simNameMatches: simNameMatches,
  );

  Verification withSimNameMatch(bool matches) => Verification(
    cnicMasked: cnicMasked,
    cnicName: cnicName,
    cnicDateOfBirth: cnicDateOfBirth,
    cnicPlausible: cnicPlausible,
    cnicSubmittedAt: cnicSubmittedAt,
    phone: phone,
    phoneVerifiedAt: phoneVerifiedAt,
    simNameMatches: matches,
  );

  /// Read from the same flat map [AccountReview] uses.
  ///
  /// The four booleans are the shape the seed and the admin panel have always
  /// written; the dates are what P1-9 added. `cnicOnFile` is honoured when
  /// there is no date beside it, so a record written before this existed still
  /// reads as having a document.
  factory Verification.fromJson(Map<String, dynamic> json) {
    final submitted = json['cnicSubmittedAt'] as String?;
    final verified = json['phoneVerifiedAt'] as String?;
    final onFile = json['cnicOnFile'] as bool? ?? false;

    return Verification(
      cnicMasked: json['cnicMasked'] as String?,
      cnicName: json['cnicName'] as String?,
      cnicDateOfBirth: json['cnicDateOfBirth'] == null
          ? null
          : DateTime.parse(json['cnicDateOfBirth'] as String),
      cnicPlausible: json['cnicPlausible'] as bool? ?? false,
      cnicSubmittedAt: submitted != null
          ? DateTime.parse(submitted)
          : (onFile ? _longAgo : null),
      phone: json['phone'] as String?,
      phoneVerifiedAt: verified != null
          ? DateTime.parse(verified)
          : ((json['phoneVerified'] as bool? ?? false) ? _longAgo : null),
      simNameMatches: json['simNameMatches'] as bool? ?? true,
    );
  }

  /// The stand-in date for a seeded record that says *what* is on file without
  /// saying when. Never shown as a date — [cnicOnFile] is the only thing that
  /// reads it — but a nullable date is how "nothing submitted" is expressed,
  /// so it needs a value that is not null.
  static final _longAgo = DateTime.utc(2000);

  /// Written flat, alongside [AccountReview]'s own fields.
  ///
  /// The booleans are kept in the output even though they are derived, because
  /// they are the shape the seed files are in and regenerating those on a
  /// schema the app can already read would be churn for its own sake.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'cnicOnFile': cnicOnFile,
    'cnicPlausible': cnicPlausible,
    'phoneVerified': phoneVerified,
    'simNameMatches': simNameMatches,
    if (cnicMasked != null) 'cnicMasked': cnicMasked,
    if (cnicName != null) 'cnicName': cnicName,
    if (cnicDateOfBirth != null)
      'cnicDateOfBirth': cnicDateOfBirth!.toIso8601String(),
    if (cnicSubmittedAt != null)
      'cnicSubmittedAt': cnicSubmittedAt!.toIso8601String(),
    if (phone != null) 'phone': phone,
    if (phoneVerifiedAt != null)
      'phoneVerifiedAt': phoneVerifiedAt!.toIso8601String(),
  };
}

/// A code sent to a phone, and what has happened to it since.
///
/// Held so that expiry, attempts and the resend cooldown are properties of a
/// stored thing rather than of whichever screen is open — otherwise closing the
/// app is a way to get unlimited guesses.
class PhoneChallenge {
  const PhoneChallenge({
    required this.phone,
    required this.code,
    required this.sentAt,
    this.attempts = 0,
  });

  final String phone;

  /// **In the demo this is stored on the device**, which is exactly what a
  /// real one must never do — a code the client holds is a code the client can
  /// read, and it would confirm nothing. It is here because there is no server
  /// to hold it instead; `SmsSender` is the seam where that changes, and P1-8b
  /// is where the code stops crossing to the device at all.
  final String code;

  final DateTime sentAt;
  final int attempts;

  PhoneChallenge withAttempt() => PhoneChallenge(
    phone: phone,
    code: code,
    sentAt: sentAt,
    attempts: attempts + 1,
  );

  factory PhoneChallenge.fromJson(Map<String, dynamic> json) => PhoneChallenge(
    phone: json['phone'] as String,
    code: json['code'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
    attempts: json['attempts'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'phone': phone,
    'code': code,
    'sentAt': sentAt.toIso8601String(),
    'attempts': attempts,
  };
}

/// Why a code was refused.
///
/// A closed list rather than a message, so the screen decides the wording and
/// the rules decide the outcome — and so a test can assert *which* refusal
/// happened rather than matching on English.
enum PhoneCheckResult {
  confirmed,

  /// Right code, too late. Distinguished from [wrong] on purpose: telling
  /// somebody to ask for a new code is different from telling them they
  /// mistyped, and one of those is not their mistake.
  expired,

  wrong,

  /// Too many guesses. The challenge is spent and a new one must be sent.
  tooManyAttempts,

  /// Nothing was sent, so there is nothing to check.
  nothingSent,
}
