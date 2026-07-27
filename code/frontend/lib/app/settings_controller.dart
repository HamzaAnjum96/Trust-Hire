import 'package:flutter/material.dart';

import '../services/local_store.dart';

/// App-level preferences. Currently just the theme, persisted locally so the
/// choice survives a restart.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  final LocalStore _store;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Null means "follow the device". Kept as an option rather than defaulting
  /// to one language, since the audience is mixed English and Urdu.
  Locale? _locale;
  Locale? get locale => _locale;

  /// Languages offered, in the order they appear in settings.
  static const supportedLocales = <Locale>[Locale('en'), Locale('ur')];

  /// False until the first-run intro has been seen. Drives whether the app
  /// opens on the intro or straight onto the map.
  bool _introSeen = false;
  bool get introSeen => _introSeen;

  void load() {
    _introSeen = _store.readFlag(StoreKeys.introSeen);

    final language = _store.readString(StoreKeys.language);
    _locale = language == null || language.isEmpty ? null : Locale(language);

    final stored = _store.readString(StoreKeys.themeMode);
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    if (_introSeen) return;
    _introSeen = true;
    notifyListeners();
    await _store.writeFlag(StoreKeys.introSeen, true);
  }

  /// Shows the intro again next launch. Useful for demonstrating the app, and
  /// for anyone who skipped past it too quickly.
  Future<void> resetIntro() async {
    _introSeen = false;
    notifyListeners();
    await _store.writeFlag(StoreKeys.introSeen, false);
  }

  /// Sets the interface language, or null to follow the device.
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    await _store.writeString(StoreKeys.language, locale?.languageCode ?? '');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    await _store.writeString(StoreKeys.themeMode, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
