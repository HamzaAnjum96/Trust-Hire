/// Where a verification code leaves the app.
///
/// **This interface is the point of the file.** Section 2 asks for "a real SMS
/// OTP (via a Pakistani SMS provider or similar)... genuinely implemented, not
/// simulated", and it is right to: a code that never leaves the device
/// confirms nothing about the phone. There is no provider to send through
/// until P1-8b stands a backend up, so the honest thing is not to pretend, but
/// to put the seam where the provider goes and be explicit about which side of
/// it is real.
///
/// Real, today: the code, its length, its expiry, the attempt limit, the resend
/// cooldown, the normalisation that makes four spellings of a number one
/// number, and every refusal in `VerificationRules`.
///
/// Not real, today: delivery. [DemoSmsSender] hands the message back to the
/// screen instead of to a network, and the screen says so where somebody can
/// read it rather than in a comment nobody will.
abstract class SmsSender {
  /// Sends [message] to [phone] in `+92...` form.
  ///
  /// Returns the message when the caller is expected to display it — which is
  /// only ever true of a demo sender. A real one returns null, because a code
  /// that comes back to the sender is a code the sender did not need to send.
  Future<String?> send({required String phone, required String message});
}

/// The one the POC uses: nothing goes anywhere.
///
/// Keeps the last message so the verification screen can show it, headed by a
/// line saying it is standing in for an SMS. Showing it is deliberate — the
/// alternative is a demo where the phone step cannot be completed at all, and a
/// step nobody can walk through is a step nobody can assess.
class DemoSmsSender implements SmsSender {
  DemoSmsSender();

  /// What "arrived", for the screen to display.
  String? lastMessage;
  String? lastPhone;

  int sent = 0;

  @override
  Future<String?> send({required String phone, required String message}) async {
    lastPhone = phone;
    lastMessage = message;
    sent += 1;
    return message;
  }
}
