import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../features/verification/verification_rules.dart';
import '../models/account.dart';
import '../models/admin.dart';
import '../models/verification.dart';
import '../services/local_store.dart';
import '../services/sms_sender.dart';

/// The account holder's side of Section 2.
///
/// The admin panel already had the *result* of verification; this is where it
/// comes from. Both read and write the same [AccountReview] row — see
/// [AccountReview.verification] — so there is no second copy for a
/// re-submission to leave behind.
///
/// **The full CNIC number never reaches storage.** [submitCnic] masks before it
/// writes and refuses anything the mask does not recognise, so there is no path
/// that stores a complete national identity number the app has no use for. The
/// schema states the same rule as a check constraint; this is the client half
/// of it, and the reason a client half is worth having is that it means the
/// number is never held on the device either.
class VerificationController extends ChangeNotifier {
  VerificationController(
    this._store, {
    this.rules = const VerificationRules(),
    SmsSender? sms,
  }) : sms = sms ?? DemoSmsSender();

  final LocalStore _store;
  final VerificationRules rules;

  /// The seam where a real provider goes. See [SmsSender].
  final SmsSender sms;

  String _userId = DemoAccounts.deviceId;
  String get userId => _userId;

  /// The name this account goes by, which is what the SIM check compares
  /// against in the demo. Set from the account roster.
  ///
  /// Empty for the device account, which the interface calls "This device"
  /// rather than naming — see [canCheckSimName], because a comparison against
  /// nothing is not a mismatch.
  String _accountName = '';

  Map<String, AccountReview> _reviews = <String, AccountReview>{};
  Map<String, CnicRecord> _cnics = <String, CnicRecord>{};
  PhoneChallenge? _challenge;

  /// The last message the demo sender produced, so the screen can show what
  /// would have arrived. Null with a real sender, and null before anything is
  /// sent.
  String? get demoMessage => sms is DemoSmsSender
      ? (sms as DemoSmsSender).lastMessage
      : null;

  Verification get mine => _reviews[_userId]?.verification ?? const Verification();

  ReviewStatus get status =>
      _reviews[_userId]?.status ?? ReviewStatus.pending;

  PhoneChallenge? get challenge => _challenge;

  bool get hasCodeOutstanding =>
      _challenge != null &&
      !rules.isSpent(_challenge!) &&
      !rules.hasExpired(_challenge!);

  Set<VerificationLimit> get limits => rules.describeLimits(mine);

  /// Whether there is anything to compare.
  ///
  /// The check needs a name on a card, a number, and a name the number is
  /// registered to. The demo stands the last one in with the account's own
  /// name, and the device account has none — so on that account the check
  /// does not run, and **not running is not a mismatch**. Reporting one would
  /// be the flag firing on the single account that has done nothing at all.
  bool get canCheckSimName =>
      mine.cnicOnFile && mine.phone != null && _accountName.trim().isNotEmpty;

  void setAccount(String id, {String name = ''}) {
    if (_userId == id && _accountName == name) return;
    _userId = id;
    _accountName = name;
    _challenge = null;
    load();
  }

  void load() {
    _reviews = {
      for (final json in _store.readCollection(StoreKeys.accountReviews) ??
          const [])
        (json['userId'] as String): AccountReview.fromJson(json),
    };

    _cnics = {
      for (final json in _store.readCollection(StoreKeys.cnicRecords) ??
          const [])
        (json['userId'] as String): CnicRecord.fromJson(json),
    };

    final raw = _store.readString(
      StoreKeys.forAccount(StoreKeys.phoneChallenge, _userId),
    );
    _challenge = null;
    if (raw != null && raw.isNotEmpty) {
      try {
        _challenge = PhoneChallenge.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } on FormatException {
        // A corrupt challenge is one nobody can answer. Dropping it costs a
        // resend; keeping it would be a step the person cannot get past.
        _challenge = null;
      }
    }

    notifyListeners();
  }

  // --- The CNIC ------------------------------------------------------------

  /// Submits a card.
  ///
  /// Returns false when the number is not thirteen digits — the one case where
  /// nothing is stored at all, because a number the mask cannot parse is a
  /// number that would have to be stored whole to be stored.
  ///
  /// A card that is well-formed but implausible for another reason (no name, a
  /// date of birth in the future) **is** stored, with `cnicPlausible` false.
  /// Section 2 sends those to a person rather than turning them away, and an
  /// upload the app silently discards is one the worker thinks succeeded.
  Future<bool> submitCnic({
    required String number,
    required String name,
    DateTime? dateOfBirth,
    String? photoReference,
    DateTime? at,
  }) async {
    final masked = rules.mask(number);
    if (masked == null) return false;

    final now = at ?? DateTime.now();
    final trimmedName = name.trim();

    final plausible = rules.isPlausibleCard(
      number: number,
      name: trimmedName,
      dateOfBirth: dateOfBirth,
      now: now,
    );

    // The SIM check needs both names. With no phone on file yet there is
    // nothing to compare, and Section 2's default is *not* suspicion — an
    // account with no number has not done anything questionable.
    final matches =
        mine.phone == null || _accountName.trim().isEmpty
        ? true
        : rules.namesMatch(trimmedName, _accountName);

    await _write(
      mine
          .withCnic(
            masked: masked,
            name: trimmedName,
            dateOfBirth: dateOfBirth,
            plausible: plausible,
            at: now,
            simNameMatches: matches,
          ),
    );

    _cnics = {
      ..._cnics,
      _userId: CnicRecord(
        userId: _userId,
        maskedNumber: masked,
        nameOnCard: trimmedName,
        submittedAt: now,
        photoReference: photoReference,
      ),
    };

    await _store.writeCollection(
      StoreKeys.cnicRecords,
      _cnics.values.map((record) => record.toJson()).toList(growable: false),
    );

    notifyListeners();
    return true;
  }

  // --- The phone -----------------------------------------------------------

  /// Sends a code to [phone].
  ///
  /// Returns false for a number that is not a Pakistani mobile, or when the
  /// resend cooldown has not elapsed — so "resend" cannot be used to spray
  /// messages at a number that is not yours.
  Future<bool> sendCode(String phone, {DateTime? at}) async {
    final normalised = rules.normalisePhone(phone);
    if (normalised == null) return false;

    final now = at ?? DateTime.now();

    // A cooldown only applies to the same number. Correcting a typo should not
    // mean waiting out a message that went to the wrong phone.
    if (_challenge != null &&
        _challenge!.phone == normalised &&
        rules.resendWaitFor(_challenge, now: now) > Duration.zero) {
      return false;
    }

    final code = rules.newCode();

    await sms.send(
      phone: normalised,
      message: 'Trust Hire: your code is $code. It expires in '
          '${VerificationRules.validFor.inMinutes} minutes.',
    );

    _challenge = PhoneChallenge(phone: normalised, code: code, sentAt: now);
    await _saveChallenge();

    // Recorded before it is confirmed, and confirmation is dropped if the
    // number changed — a tick beside a number nobody has sent anything to is
    // the one outcome this step must not produce.
    await _write(mine.withPhone(normalised));

    notifyListeners();
    return true;
  }

  Duration resendWait({DateTime? at}) =>
      rules.resendWaitFor(_challenge, now: at);

  /// Checks what somebody typed.
  ///
  /// A wrong answer costs an attempt; expiry and exhaustion do not, because
  /// neither is a guess.
  Future<PhoneCheckResult> confirmCode(String entered, {DateTime? at}) async {
    final now = at ?? DateTime.now();
    final result = rules.check(_challenge, entered, now: now);

    switch (result) {
      case PhoneCheckResult.confirmed:
        await _write(mine.withPhoneConfirmed(now));
        await _recheckSimName();
        _challenge = null;
        await _store.remove(
          StoreKeys.forAccount(StoreKeys.phoneChallenge, _userId),
        );

      case PhoneCheckResult.wrong:
        _challenge = _challenge!.withAttempt();
        await _saveChallenge();

      case PhoneCheckResult.expired:
      case PhoneCheckResult.tooManyAttempts:
      case PhoneCheckResult.nothingSent:
        break;
    }

    notifyListeners();
    return result;
  }

  /// The CNIC-SIM name comparison, run at the moment both halves exist.
  ///
  /// **A flag, never a rejection.** It moves the account up the admin queue and
  /// changes nothing else — Section 2 expects false positives, and a worker on
  /// a family member's SIM is the ordinary case.
  Future<void> _recheckSimName() async {
    if (!canCheckSimName) return;
    await _write(
      mine.withSimNameMatch(rules.namesMatch(mine.cnicName, _accountName)),
    );
  }

  // --- Storage -------------------------------------------------------------

  Future<void> _write(Verification verification) async {
    final existing = _reviews[_userId] ?? AccountReview(userId: _userId);

    _reviews = {
      ..._reviews,
      _userId: existing.copyWith(verification: verification),
    };

    await _store.writeCollection(
      StoreKeys.accountReviews,
      _reviews.values.map((review) => review.toJson()).toList(growable: false),
    );
  }

  Future<void> _saveChallenge() async {
    final key = StoreKeys.forAccount(StoreKeys.phoneChallenge, _userId);
    if (_challenge == null) {
      await _store.remove(key);
      return;
    }
    await _store.writeString(key, jsonEncode(_challenge!.toJson()));
  }
}
