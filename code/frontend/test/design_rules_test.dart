import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/core/theme.dart';

/// The design rules that can be checked by reading the source.
///
/// **A rule that lives only in prose gets broken in the next session.** The
/// 0.23 redesign set these down in `documents/design/`, and within a week one
/// was already broken (the map's attribution at 10px). Each rule here says
/// where its value is allowed to live, so a reskin changes one file and a
/// screen cannot quietly drift from it.
///
/// Every rule was proven by breaking it once and watching this file fail.
void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('/l10n/'))
      .toList();

  bool inCore(File f) => f.path.contains('lib/core/');

  /// Every line of every file outside [except] that matches [pattern], as
  /// `path:line: text`, so a failure says exactly where to look.
  List<String> offences(
    RegExp pattern, {
    bool Function(File)? except,
    bool Function(String line)? unless,
  }) {
    final found = <String>[];
    for (final file in sources) {
      if (except != null && except(file)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (!pattern.hasMatch(line)) continue;
        if (unless != null && unless(line)) continue;
        found.add('${file.path}:${i + 1}: ${line.trim()}');
      }
    }
    return found;
  }

  test('screens take colours from roles, never from the palette', () {
    // `AppColours` in lib/core/roles.dart is the only place a palette colour
    // is named. A screen that reaches past it is a screen a reskin misses.
    expect(
      offences(RegExp(r'BrandColours\.'), except: inCore),
      isEmpty,
      reason: 'use context.colours.<role> instead',
    );
  });

  test('no Material colour constants outside the theme', () {
    // Colors.transparent is not a colour. The fading row's black is an alpha
    // mask for a gradient, never drawn.
    expect(
      offences(
        RegExp(r'\bColors\.\w+'),
        except: (f) => inCore(f) || f.path.endsWith('widgets/fading_row.dart'),
        unless: (line) => RegExp(
          r'\bColors\.\w+',
        ).allMatches(line).every((m) => m.group(0) == 'Colors.transparent'),
      ),
      isEmpty,
    );
  });

  test('no raw colour values outside the theme', () {
    expect(offences(RegExp(r'Color\(0x'), except: inCore), isEmpty);
  });

  test('the theme\'s own colours are reached through roles too', () {
    // colorScheme.primary is a fill colour; as text in dark mode it failed
    // AA. The roles say which job a colour is doing: action, accentText,
    // highlight.
    expect(
      offences(
        // Through any name: a local `scheme.secondary` is the same colour,
        // and it is how peacock reached the "Your posting" badge.
        RegExp(
          r'\b(colorScheme|scheme)\.(primary|onPrimary|secondary|onSecondary|tertiary)\b',
        ),
        except: inCore,
      ),
      isEmpty,
      reason: 'use context.colours.action / accentText / highlight / voice',
    );
  });

  test('peacock is for voice notes and nothing else', () {
    // The direction's rule. The voice role may appear only where a voice
    // note is drawn: the player, the recorder on the post form, the voice
    // chips on a row and a preview, and the intro's voice picture. In 0.24
    // it had spread to the photo tiles and a missing-photo glyph.
    const voiceFiles = {
      'lib/widgets/voice_note_player.dart',
      'lib/features/create_job/media_fields.dart',
      'lib/features/jobs/job_row.dart',
      'lib/features/map/map_screen.dart',
      'lib/features/onboarding/onboarding_screen.dart',
    };
    expect(
      offences(
        RegExp(r'colours\.voice\b'),
        except: (f) => inCore(f) || voiceFiles.contains(f.path),
      ),
      isEmpty,
    );
    // And within the post form, only on its voice controls.
    final media = File(
      'lib/features/create_job/media_fields.dart',
    ).readAsStringSync();
    final photoTile = media.substring(media.indexOf('class _AddTile'));
    expect(
      photoTile.substring(0, photoTile.indexOf('\n}\n')),
      isNot(contains('colours.voice')),
    );
  });

  test('nothing is set smaller than 12px', () {
    // Section 11: "Do not use text smaller than 12px."
    final small = <String>[];
    for (final line in offences(RegExp(r'fontSize:\s*\d'))) {
      final size = double.parse(
        RegExp(r'fontSize:\s*([\d.]+)').firstMatch(line)!.group(1)!,
      );
      if (size < 12) small.add(line);
    }
    expect(small, isEmpty);
  });

  test('tracking is set in the type scale, nowhere else', () {
    expect(
      offences(
        RegExp(r'letterSpacing:'),
        except: (f) => f.path.endsWith('lib/core/tokens.dart'),
      ),
      isEmpty,
    );
  });

  test('one motion curve, named in the tokens', () {
    expect(
      offences(RegExp(r'\bCurves\.\w+|\bCubic\('), except: inCore),
      isEmpty,
      reason: 'use BrandMotion.curve',
    );
  });

  test('one icon family: Material rounded', () {
    // Since 0.24 every glyph is from the rounded set: filled shapes read
    // better than thin outlines at small sizes in bright light. An outline
    // that carries state (an unsaved bookmark, an empty star) is the rounded
    // set's own _border variant.
    expect(
      offences(
        RegExp(r'Icons\.\w+'),
        unless: (line) => RegExp(
          r'Icons\.\w+',
        ).allMatches(line).every((m) => m.group(0)!.endsWith('_rounded')),
      ),
      isEmpty,
    );
  });

  test('rows are rows: no card inside a job or inbox row', () {
    // Cards are for things that sit above the page. A list draws hairlines.
    for (final path in [
      'lib/features/jobs/job_row.dart',
      'lib/widgets/inbox_row.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source.contains(RegExp(r'\bCard\(')), isFalse, reason: path);
    }
  });

  test('one page transition, whatever OS the browser reports', () {
    // The site is the app, and a browser reports the visitor's OS: before
    // 0.34 a screen zoomed in on Windows, slid on a Mac, faded on a phone.
    for (final theme in [BrandTheme.light, BrandTheme.dark]) {
      for (final platform in TargetPlatform.values) {
        expect(
          theme.pageTransitionsTheme.builders[platform],
          isA<FadeForwardsPageTransitionsBuilder>(),
          reason: platform.name,
        );
      }
    }
  });
}
