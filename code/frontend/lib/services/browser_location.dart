/// The browser's address bar, on the web build — and nothing anywhere else.
///
/// A conditional export rather than a `kIsWeb` check, because the web half
/// imports `package:web`, which does not compile for Android or iOS.
library;

export 'browser_location_stub.dart'
    if (dart.library.js_interop) 'browser_location_web.dart';
