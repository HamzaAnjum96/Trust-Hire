import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The web shell is the first thing anyone sees, and the only part of the
/// product a crawler that does not run JavaScript ever sees. It shipped as
/// Flutter's default — `trust_hire`, "A new Flutter project.", and a blue that
/// appears nowhere else in the brand — for thirteen sprints without anyone
/// noticing, because nothing looks at it.
///
/// These assertions are about the defaults specifically. Re-running
/// `flutter create` over the project restores every one of them silently.
void main() {
  final index = File('web/index.html').readAsStringSync();
  final manifest =
      jsonDecode(File('web/manifest.json').readAsStringSync())
          as Map<String, dynamic>;

  group('index.html', () {
    test('names the product, not the package', () {
      expect(index, contains('<title>Trust Hire'));
      expect(index, isNot(contains('<title>trust_hire')));
    });

    test('describes the product to a search engine', () {
      final description = RegExp(
        r'<meta name="description" content="([^"]+)"',
      ).firstMatch(index)?.group(1);

      expect(description, isNotNull);
      expect(description, isNot('A new Flutter project.'));
      // Long enough to be a description rather than a label.
      expect(description!.length, greaterThan(60));
    });

    test('is shareable', () {
      for (final property in [
        'og:title',
        'og:description',
        'og:image',
        'twitter:card',
      ]) {
        expect(index, contains(property), reason: 'missing $property');
      }
    });

    test('wears the brand colour', () {
      expect(index, contains('<meta name="theme-color" content="#7A263A">'));
      expect(index, isNot(contains('0175C2')));
    });

    test('declares a language and a viewport', () {
      expect(index, contains('<html lang='));
      expect(index, contains('name="viewport"'));
    });

    test('says something before the engine loads', () {
      // Without this the page is blank until Flutter paints, which on a slow
      // connection is indistinguishable from a failed deploy.
      expect(index, contains('id="boot"'));
      expect(index, contains('flutter-first-frame'));
      expect(index, contains('<noscript>'));
    });

    test('the loading animation stops for reduced motion', () {
      expect(index, contains('prefers-reduced-motion'));
    });
  });

  group('manifest.json', () {
    test('names the product, not the package', () {
      expect(manifest['name'], 'Trust Hire');
      expect(manifest['short_name'], 'Trust Hire');
    });

    test('describes the product', () {
      expect(manifest['description'], isNot('A new Flutter project.'));
      expect((manifest['description'] as String).length, greaterThan(60));
    });

    test('wears the brand colours', () {
      expect(manifest['theme_color'], '#7A263A');
      expect(manifest['background_color'], '#F4E9DE');
    });

    test('is not locked to portrait', () {
      // The same build runs on a desktop browser, where portrait-only is
      // meaningless at best.
      expect(manifest['orientation'], isNot('portrait-primary'));
    });

    test('ships every icon it lists', () {
      final icons = (manifest['icons'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(icons, isNotEmpty);
      for (final icon in icons) {
        final path = File('web/${icon['src']}');
        expect(path.existsSync(), isTrue, reason: '${icon['src']} is missing');
        expect(path.lengthSync(), greaterThan(0));
      }

      expect(
        icons.where((i) => i['purpose'] == 'maskable'),
        isNotEmpty,
        reason: 'a launcher crops a non-maskable icon badly',
      );
    });
  });
}
