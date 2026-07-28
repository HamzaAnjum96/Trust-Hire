import 'dart:math';

import '../../models/verification.dart';

/// Section 2, as rules.
///
/// Pure functions over plain data, like every rules class before it. Three of
/// them are the whole of what the app can honestly claim about who somebody is:
/// a number is the right shape, a phone answered a code, and two names look
/// like the same person. None is an identity check, and [describeLimits] exists
/// so no screen can show the results without saying so.
class VerificationRules {
  const VerificationRules({this.random});

  /// Injectable so a test can assert on a known code. Null means a fresh
  /// [Random.secure] per call.
  final Random? random;

  // --- The CNIC ------------------------------------------------------------

  /// A Pakistani CNIC is thirteen digits, written `12345-1234567-1`.
  static final _cnicPattern = RegExp(r'^\d{5}-\d{7}-\d$');

  /// Accepts the number with or without its dashes, because a keypad does not
  /// have one and refusing thirteen correct digits over punctuation is the
  /// kind of thing that stops somebody using the app.
  String? normaliseCnic(String? input) {
    final digits = (input ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 13) return null;

    return '${digits.substring(0, 5)}-${digits.substring(5, 12)}-'
        '${digits.substring(12)}';
  }

  /// **A shape check, not an identity check.** Section 13 rules out any live
  /// NADRA lookup, so the most this can honestly claim is that somebody typed
  /// something the right length in the right pattern.
  bool isPlausibleCnic(String? number) {
    final normalised = normaliseCnic(number);
    if (normalised == null) return false;
    return _cnicPattern.hasMatch(normalised);
  }

  /// Section 2 asks the automated check to confirm "valid CNIC number format,
  /// name/DOB present" — all three, which is why a well-formed number with no
  /// name behind it is not plausible.
  ///
  /// The date of birth is checked for being a date a living adult could have,
  /// not against anything: there is nothing to check it against.
  bool isPlausibleCard({
    String? number,
    String? name,
    DateTime? dateOfBirth,
    DateTime? now,
  }) {
    if (!isPlausibleCnic(number)) return false;
    if ((name ?? '').trim().length < 3) return false;
    if (dateOfBirth == null) return false;

    final today = now ?? DateTime.now();
    final years = _yearsBetween(dateOfBirth, today);
    return years >= 18 && years <= 120;
  }

  /// The only thing that produces a stored CNIC.
  ///
  /// **The whole number never reaches storage.** Keeping the last two digits of
  /// the middle block and the check digit is enough for an admin to match a
  /// document against a claim during a dispute, and holding a complete national
  /// identity number the app has no use for — Section 13 rules out looking one
  /// up — would be keeping it for no reason anybody could name.
  ///
  /// Returns null for anything that is not a CNIC, so there is no path where a
  /// malformed number is stored unmasked because the mask did not recognise it.
  String? mask(String? number) {
    final normalised = normaliseCnic(number);
    if (normalised == null) return null;

    final middle = normalised.substring(6, 13);
    final check = normalised.substring(14);
    return '*****-*****${middle.substring(5)}-$check';
  }

  // --- The phone -----------------------------------------------------------

  /// Pakistani mobile numbers, written the four ways people write them:
  /// `03001234567`, `3001234567`, `+923001234567`, `00923001234567`.
  ///
  /// Normalised to `+92` form so the same phone typed four ways is one number —
  /// which matters because the SIM check and the fraud loophole it closes are
  /// both about *which* number, and four spellings would be four accounts.
  String? normalisePhone(String? input) {
    var digits = (input ?? '').replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('0092')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('92')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // A Pakistani mobile is 3xx followed by seven digits.
    if (digits.length != 10 || !digits.startsWith('3')) return null;

    return '+92$digits';
  }

  bool isPlausiblePhone(String? input) => normalisePhone(input) != null;

  /// `+923001234567` → `+92 300 1234567`, which is how it is read aloud.
  String formatPhone(String? normalised) {
    if (normalised == null || normalised.length != 13) return normalised ?? '';
    return '+92 ${normalised.substring(3, 6)} ${normalised.substring(6)}';
  }

  // --- The SIM-name check --------------------------------------------------

  /// Whether two names look like the same person.
  ///
  /// **This part is real; where the second name comes from is not.** Section 2
  /// describes a third-party API returning the name a SIM is registered to, and
  /// there is no such API wired up — the demo compares against the name on the
  /// account. The comparison itself is the thing that decides the flag, so it
  /// is written properly rather than stubbed.
  ///
  /// Deliberately generous. It is aimed at "bought a new SIM after a ban",
  /// which produces an entirely different name, not at spelling. So:
  ///
  ///  * case and extra spaces are ignored;
  ///  * `Muhammad`, `Mohammad`, `Mohammed` and `Md` are one word, because they
  ///    are one name spelled by whoever filled the form in;
  ///  * an honorific is not part of anybody's name;
  ///  * a shared given *and* family name is a match even when a middle name
  ///    appears on one document and not the other.
  bool namesMatch(String? a, String? b) {
    final left = _nameWords(a);
    final right = _nameWords(b);
    if (left.isEmpty || right.isEmpty) return false;

    if (left.first == right.first && left.last == right.last) return true;

    // Otherwise, most of one name appearing in the other. Two of three words
    // shared is a person who wrote their name differently; one is a coincidence
    // in a country where a great many people share a family name.
    final shared = left.where(right.contains).length;
    return shared >= 2 || (shared == 1 && left.length == 1 && right.length == 1);
  }

  static const _honorifics = {
    'mr', 'mrs', 'ms', 'miss', 'dr', 'engr', 'hafiz', 'syed', 'mian', 'ch',
    'chaudhry', 'malik', 'sheikh',
  };

  static const _muhammad = {'muhammad', 'mohammad', 'mohammed', 'mohd', 'md'};

  List<String> _nameWords(String? name) {
    final words = (name ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => _muhammad.contains(word) ? 'muhammad' : word)
        .where((word) => !_honorifics.contains(word))
        .toList();

    // An honorific-only string is still a name to somebody; better to compare
    // it than to treat it as nothing.
    return words.isEmpty ? _rawWords(name) : words;
  }

  List<String> _rawWords(String? name) => (name ?? '')
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  // --- The code ------------------------------------------------------------

  /// Six digits, which is what every Pakistani service sends.
  static const codeLength = 6;

  /// Long enough to find the phone and read the message, short enough that an
  /// old code is not still live when somebody else picks the handset up.
  static const validFor = Duration(minutes: 5);

  /// Five wrong guesses ends the challenge. A six-digit code has a million
  /// values, so this is not what makes guessing hopeless — it is what stops a
  /// challenge being an open-ended thing to sit and try against.
  static const maxAttempts = 5;

  /// So "resend" cannot be used to spray messages at a number that is not
  /// yours. Also the reason the button says how long is left rather than
  /// silently doing nothing.
  static const resendAfter = Duration(seconds: 30);

  String newCode() {
    final rng = random ?? Random.secure();
    final value = rng.nextInt(1000000);
    return value.toString().padLeft(codeLength, '0');
  }

  bool hasExpired(PhoneChallenge challenge, {DateTime? now}) =>
      (now ?? DateTime.now()).difference(challenge.sentAt) > validFor;

  bool isSpent(PhoneChallenge challenge) =>
      challenge.attempts >= maxAttempts;

  Duration resendWaitFor(PhoneChallenge? challenge, {DateTime? now}) {
    if (challenge == null) return Duration.zero;

    final since = (now ?? DateTime.now()).difference(challenge.sentAt);
    final left = resendAfter - since;
    return left.isNegative ? Duration.zero : left;
  }

  /// The outcome of somebody typing [entered].
  ///
  /// Order matters. A spent or expired challenge is reported as such even when
  /// the code is right, because the honest answer to "I typed it correctly and
  /// it said wrong" is that the code had run out — and a screen that cannot
  /// tell those apart teaches people to distrust the one that is their fault.
  PhoneCheckResult check(
    PhoneChallenge? challenge,
    String entered, {
    DateTime? now,
  }) {
    if (challenge == null) return PhoneCheckResult.nothingSent;
    if (isSpent(challenge)) return PhoneCheckResult.tooManyAttempts;
    if (hasExpired(challenge, now: now)) return PhoneCheckResult.expired;

    final typed = entered.replaceAll(RegExp(r'[^0-9]'), '');
    if (typed == challenge.code) return PhoneCheckResult.confirmed;

    return PhoneCheckResult.wrong;
  }

  // --- What all of this does not establish ---------------------------------

  /// Which of Section 2's caveats a screen has to be showing.
  ///
  /// A list rather than a paragraph so the screens cannot show the results
  /// while quietly dropping the qualification — the caveat travels with the
  /// signal it qualifies, which is the only way it stays attached.
  Set<VerificationLimit> describeLimits(Verification verification) => {
    if (verification.cnicOnFile) VerificationLimit.noGovernmentLookup,
    if (verification.cnicOnFile) VerificationLimit.photoUnreviewed,
    if (verification.isFlagged) VerificationLimit.simMismatchIsNotGuilt,
  };

  static int _yearsBetween(DateTime from, DateTime to) {
    var years = to.year - from.year;
    final hadBirthday =
        to.month > from.month ||
        (to.month == from.month && to.day >= from.day);
    if (!hadBirthday) years -= 1;
    return years;
  }
}

/// The things a verification result does **not** mean.
enum VerificationLimit {
  /// The number is the right shape. Nobody has asked NADRA whether it exists.
  noGovernmentLookup,

  /// A photo was uploaded and nobody has looked at it, by design.
  photoUnreviewed,

  /// A mismatch is a reason for a person to look, not evidence of anything.
  simMismatchIsNotGuilt,
}
