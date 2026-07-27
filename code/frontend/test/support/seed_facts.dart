import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Facts about the bundled seed data, read from the file rather than typed in.
///
/// Tests kept hardcoding "12 jobs", which meant every change to the demo data
/// broke a dozen unrelated assertions. Reading the counts keeps those tests
/// about behaviour — that seeding happened, that a deletion survived — rather
/// than about how many examples happen to ship.
class SeedFacts {
  const SeedFacts._();

  static Future<int> jobCount() async => _countOf('assets/seed/jobs.json');

  static Future<int> userCount() async => _countOf('assets/seed/users.json');

  static Future<int> _countOf(String asset) async {
    final raw = await rootBundle.loadString(asset);
    return (jsonDecode(raw) as List<dynamic>).length;
  }
}
