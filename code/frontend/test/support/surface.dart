import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sizes the test surface, and puts it back afterwards.
///
/// Flutter's default test window is 800x600, which since the adaptive layout
/// landed is a *medium* window — so a test that says nothing about size has
/// been quietly asserting tablet behaviour. Every test that cares now says
/// which shape of screen it means.
extension TestSurface on WidgetTester {
  /// A handset held upright.
  Future<void> useCompactSurface() => _resize(const Size(390, 844));

  /// A large phone in landscape, or a tablet.
  Future<void> useMediumSurface() => _resize(const Size(800, 600));

  /// A desktop browser.
  Future<void> useExpandedSurface() => _resize(const Size(1440, 900));

  Future<void> _resize(Size size) async {
    view.devicePixelRatio = 1.0;
    view.physicalSize = size;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  }
}
