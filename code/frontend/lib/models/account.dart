/// One of the people you can be while trying the app out.
///
/// Section 13a excludes authentication from the POC, so "who am I" here is a
/// choice rather than a credential. Making that choice explicit is what lets a
/// single device show both sides of a hire: post as one person, bid as
/// another, accept, finish, and rate each other. Without it the bidding
/// screens, the job lifecycle and the mutual ratings can each only ever be
/// seen from one end, which is the half that proves nothing.
///
/// These are **not** user accounts. There is no password, no verification and
/// no privacy between them — everything lives in the same browser storage and
/// switching is a menu item. P1-8 replaces the whole idea with real accounts
/// on the backend.
class DemoAccount {
  const DemoAccount({
    required this.id,
    this.name,
    this.area,
    this.isAdmin = false,
    this.isSeeded = true,
  });

  final String id;

  /// Null for [DemoAccounts.device], which the interface names in the
  /// reader's own language rather than carrying an English "You" through the
  /// data layer.
  final String? name;

  /// A neighbourhood and city, never an address — the same granularity the
  /// rest of the app shows.
  final String? area;

  /// Whether this is the account the app starts on, and the one that owns
  /// anything posted before demo accounts existed.
  bool get isDevice => id == DemoAccounts.deviceId;

  /// Whether this account can see the admin panel.
  ///
  /// A property of the account rather than a setting, because becoming
  /// somebody is already how this app changes what you can do — and an admin
  /// switch on a settings screen would be a switch anybody could find.
  final bool isAdmin;

  /// Whether this person exists in the seed data. False for the two accounts
  /// the app invents: the device, and staff.
  final bool isSeeded;

  /// Two letters for the avatar. The device account has no name to take them
  /// from, so the caller supplies its label.
  String initialsOf(String label) {
    final parts = (name ?? label).trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters;
    return '${parts.first.characters}${parts.last.characters}';
  }
}

extension on String {
  /// First character, uppercased — safe on an empty string.
  String get characters => isEmpty ? '' : substring(0, 1).toUpperCase();
}

/// The fixed cast the demo switcher offers.
///
/// Five of them are people from the seed data, chosen one per city and each
/// with jobs already posted, so switching to one lands on a populated "my
/// postings" list rather than an empty screen that looks broken. Their names
/// are duplicated from `assets/seed/users.json` so the switcher can be drawn
/// before the seed has loaded; `test/account_test.dart` fails if the two ever
/// disagree.
class DemoAccounts {
  const DemoAccounts._();

  /// The account the app has always been. Everything posted, bid and earned
  /// before the switcher existed belongs to it.
  static const deviceId = 'local-user';

  static const device = DemoAccount(id: deviceId, isSeeded: false);

  /// Trust Hire's own staff, so the admin panel is reachable in a demo.
  ///
  /// Not a person in the seed — nobody posts jobs as the platform — and the
  /// only account with [DemoAccount.isAdmin] set.
  static const staffId = 'trust-hire-staff';
  static const staff = DemoAccount(
    id: staffId,
    name: 'Trust Hire staff',
    isAdmin: true,
    isSeeded: false,
  );

  static const roster = <DemoAccount>[
    device,
    DemoAccount(id: 'user-003', name: 'Hina Butt', area: 'F-7, Islamabad'),
    DemoAccount(
      id: 'user-009',
      name: 'Usman Raza',
      area: 'Johar Town, Lahore',
    ),
    DemoAccount(
      id: 'user-016',
      name: 'Bilal Awan',
      area: 'Gulshan-e-Iqbal, Karachi',
    ),
    DemoAccount(
      id: 'user-017',
      name: 'Shahid Siddiqui',
      area: 'Saddar, Peshawar',
    ),
    DemoAccount(
      id: 'user-001',
      name: 'Sadia Iqbal',
      area: 'Sheikh Maltoon, Mardan',
    ),
    staff,
  ];

  /// The account with this id, falling back to [device].
  ///
  /// A fallback rather than a throw: an id can outlive a roster edit, and the
  /// consequence of not recognising one is that somebody is themselves again,
  /// not that the app cannot start.
  static DemoAccount byId(String? id) => roster.firstWhere(
    (account) => account.id == id,
    orElse: () => device,
  );
}
