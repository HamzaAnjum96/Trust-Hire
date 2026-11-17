import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `documents/product/claims.md` lists every promise the interface makes and
/// the rule that keeps it true. This holds the two ends together: a listed
/// string must still exist, and a listed rule must still be in the sweep —
/// so a promise cannot outlive the code that kept it, unnoticed.
void main() {
  final register = File('../../documents/product/claims.md').readAsLinesSync();
  final strings =
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final sweep = File('tool/sweep_tests.py').readAsStringSync();
  final rules = RegExp(
    r'name="([^"]+)"',
  ).allMatches(sweep).map((m) => m.group(1)!).toSet();

  // Table rows: | `key` | promise | `rule` or none | note |
  final rows = [
    for (final line in register)
      if (RegExp(r'^\| `\w+` \|').hasMatch(line))
        line.split('|').map((cell) => cell.trim()).toList(),
  ];

  test('the register is not empty', () {
    expect(rows.length, greaterThan(10));
  });

  test('every claimed string still exists', () {
    for (final row in rows) {
      final key = row[1].replaceAll('`', '');
      expect(strings.containsKey(key), isTrue, reason: '$key is gone');
    }
  });

  test('every claim names a rule the sweep breaks, or says why not', () {
    for (final row in rows) {
      final key = row[1];
      final rule = row[3];
      if (rule == 'none') {
        expect(row[4], isNotEmpty, reason: '$key has no rule and no reason');
        continue;
      }
      expect(
        rules.contains(rule.replaceAll('`', '')),
        isTrue,
        reason: '$key claims $rule, which is not in tool/sweep_tests.py',
      );
    }
  });
}
