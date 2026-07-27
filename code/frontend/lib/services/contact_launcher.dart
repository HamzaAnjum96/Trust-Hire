import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands a phone number off to the dialler or to WhatsApp.
///
/// The POC stops at *finding* work, which makes it impossible to test whether
/// anyone would act on it. Handing off to apps people already use closes that
/// loop without needing a backend, an account, or a messaging system.
///
/// Every method returns whether the hand-off worked, so the caller can say so
/// rather than appearing to do nothing.
class ContactLauncher {
  const ContactLauncher();

  /// Strips everything a person might type but a dialler cannot use, while
  /// keeping a leading `+` so international numbers survive.
  static String normalise(String number) {
    final trimmed = number.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return trimmed.startsWith('+') ? '+$digits' : digits;
  }

  /// The form WhatsApp expects: digits only, country code included.
  ///
  /// A Pakistani number written the local way — `0300 1234567` — needs the
  /// leading zero swapped for the country code, which is the single most
  /// common way a WhatsApp link fails.
  static String? whatsAppNumber(String number, {String countryCode = '92'}) {
    final normalised = normalise(number);
    final digits = normalised.replaceAll('+', '');

    if (digits.length < 7) return null;
    if (normalised.startsWith('+')) return digits;
    if (digits.startsWith('0')) return '$countryCode${digits.substring(1)}';
    if (digits.startsWith(countryCode)) return digits;

    return '$countryCode$digits';
  }

  Future<bool> call(String number) =>
      _open(Uri(scheme: 'tel', path: normalise(number)));

  Future<bool> whatsApp(String number, {required String message}) async {
    final target = whatsAppNumber(number);
    if (target == null) return false;

    return _open(
      Uri.https('wa.me', '/$target', {'text': message}),
    );
  }

  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      if (kDebugMode) debugPrint('Could not open $uri: $error');
      return false;
    }
  }
}
