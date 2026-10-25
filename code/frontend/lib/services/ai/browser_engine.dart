/// The browser's model runtime: WebLLM on the web build, and an engine that
/// says "unsupported" everywhere else.
library;

import 'browser_engine_base.dart';
import 'browser_engine_stub.dart'
    if (dart.library.js_interop) 'browser_engine_web.dart'
    as platform;

export 'browser_engine_base.dart';

BrowserEngine createBrowserEngine() => platform.createBrowserEngine();
