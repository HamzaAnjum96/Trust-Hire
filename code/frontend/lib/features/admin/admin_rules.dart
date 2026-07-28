import '../../models/admin.dart';

/// Section 12, as rules — and Section 2's checks, which are the things an
/// approval decision is actually made on.
///
/// Pure functions over plain data, like every rules class before it. The one
/// here that matters most is [mayOpenCnic]: it is the difference between a
/// document that is looked at when there is a reason and a document staff can
/// browse.
class AdminRules {
  const AdminRules();

  /// A Pakistani CNIC is thirteen digits, written `12345-1234567-1`.
  ///
  /// **A shape check, not an identity check**, and the panel says so wherever
  /// it shows the result. Section 13 rules out any live NADRA lookup, so the
  /// most this can honestly claim is that somebody typed something the right
  /// length in the right pattern.
  static final _cnicPattern = RegExp(r'^\d{5}-\d{7}-\d$');

  bool isPlausibleCnic(String? number) {
    if (number == null) return false;
    return _cnicPattern.hasMatch(number.trim());
  }

  /// Whether an admin may pull up [userId]'s CNIC photo right now.
  ///
  /// **Only on an open dispute naming them.** Section 2 is explicit that the
  /// photo "sits unreviewed unless a dispute is raised later, at which point
  /// an admin manually pulls it up" — so this is the whole access rule, and it
  /// is a function rather than a checkbox on a screen precisely so that no
  /// screen can be built that forgets to ask.
  ///
  /// A resolved dispute does not keep the door open. The reason to look was
  /// the complaint, and the complaint is finished.
  bool mayOpenCnic(String userId, {required Iterable<Dispute> disputes}) =>
      disputes.any(
        (dispute) => dispute.aboutUserId == userId && dispute.isOpen,
      );

  /// The queue, in the order a human should work through it.
  ///
  /// Flagged accounts first — a SIM-name mismatch is the one signal that
  /// needs a person rather than a rule — then oldest first, so nobody waits
  /// forever because somebody newer keeps arriving.
  List<AccountReview> queue(Iterable<AccountReview> reviews) {
    final pending = reviews.where((review) => review.needsDecision).toList()
      ..sort((a, b) {
        if (a.isFlagged != b.isFlagged) return a.isFlagged ? -1 : 1;
        return a.userId.compareTo(b.userId);
      });

    return pending;
  }

  /// Whether a suspended account can be put back. Always — Section 12 calls
  /// this "full CRUD scope", and a suspension nobody can undo is a deletion
  /// wearing a softer word.
  bool mayReinstate(AccountReview review) =>
      review.status == ReviewStatus.suspended;

  /// Whether an override needs a written reason.
  ///
  /// **Anything that moves money or takes access does.** Section 12's whole
  /// argument for the audit log is that "manual overrides remain traceable
  /// rather than being a black box", and an entry reading "adjusted balance by
  /// -4,000" with no reason is exactly the black box it is meant to prevent.
  bool needsNote(AdminAction action) => action.isOverride;

  /// Whether [note] is enough of a reason to be worth logging.
  ///
  /// Deliberately low — a word is allowed. The point is to stop an empty
  /// field, not to grade somebody's writing.
  bool isUsableNote(String? note) => (note?.trim().length ?? 0) >= 3;
}
