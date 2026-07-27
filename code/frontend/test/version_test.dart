import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/core/app_version.dart';

/// The version is shown in the app and used to tell one deployed build from
/// another, so a mirror that has drifted from `pubspec.yaml` is worse than no
/// version at all — it would confidently name the wrong build.
void main() {
  test('the constant matches pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .map((l) => l.trim())
        .firstWhere(
          (l) => l.startsWith('version:'),
          orElse: () => fail('pubspec.yaml has no version line'),
        );

    final declared = line.substring('version:'.length).trim();

    expect(
      declared,
      '${AppVersion.name}+${AppVersion.build}',
      reason:
          'pubspec.yaml and lib/core/app_version.dart disagree — '
          'update both, or the app will name the wrong build',
    );
  });

  test('the label reads as a version', () {
    expect(AppVersion.label, 'v${AppVersion.name} (${AppVersion.build})');
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(AppVersion.name), isTrue);
  });
}
