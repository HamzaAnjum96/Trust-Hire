/// The app version, as a compile-time constant.
///
/// **`pubspec.yaml` is the source of truth.** This mirrors it so the version
/// can be shown without a plugin or an async lookup, and
/// `test/version_test.dart` fails the build if the two ever disagree.
///
/// **Bump this on every push that changes the app.** It is the only way to
/// tell, from a deployed build, whether the change you are looking at is the
/// one you pushed — the web build is served from a URL with no commit in it,
/// and a stale cache looks exactly like a broken deploy.
///
/// - Patch (`0.1.1`) — fixes and small changes within a sprint.
/// - Minor (`0.2.0`) — a completed sprint.
/// - Major (`1.0.0`) — reserved for a first real release.
class AppVersion {
  const AppVersion._();

  /// Must match the `version:` line in `pubspec.yaml`, without the build
  /// number after the `+`.
  static const name = '0.3.0';

  /// The build number — the part after the `+` in `pubspec.yaml`. Increments
  /// on every push, and never resets.
  static const build = 4;

  /// What the app shows: `v0.3.0 (4)`.
  static String get label => 'v$name ($build)';
}
