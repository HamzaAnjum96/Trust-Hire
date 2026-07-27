import 'package:flutter/material.dart';

import '../services/local_store.dart';

/// App-level preferences. Currently just the theme, persisted locally so the
/// choice survives a restart.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  final LocalStore _store;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void load() {
    final stored = _store.readString(StoreKeys.themeMode);
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
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
