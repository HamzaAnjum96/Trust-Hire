import 'package:web/web.dart' as web;

/// Swaps the address without navigating or adding a history entry.
///
/// The current history state is kept as it is: Flutter's own history handling
/// reads it, and replacing it with nothing would confuse the back button.
void replaceBrowserLocation(Uri location) {
  web.window.history.replaceState(
    web.window.history.state,
    '',
    location.toString(),
  );
}
