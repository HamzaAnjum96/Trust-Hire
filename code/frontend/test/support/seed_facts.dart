import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:trust_hire/models/job_tag.dart';

/// Facts about the bundled seed data, read from the file rather than typed in.
///
/// Tests kept hardcoding "12 jobs", which meant every change to the demo data
/// broke a dozen unrelated assertions. Reading the counts keeps those tests
/// about behaviour — that seeding happened, that a deletion survived — rather
/// than about how many examples happen to ship.
class SeedFacts {
  const SeedFacts._();

  static Future<int> jobCount() async => _countOf('assets/seed/jobs.json');

  /// Seeded jobs a worker on the default tag can see — which since P1-1 is a
  /// fraction of the whole file, and is the number the map actually shows on
  /// a first launch.
  static Future<int> generalJobCount() async {
    final jobs = (await readJsonAsset('assets/seed/jobs.json') as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return jobs
        .where(
          (job) => (job['tags'] as List<dynamic>? ?? const []).any(
            (tag) => JobTag.defaultWorkerTags.any((d) => d.id == tag),
          ),
        )
        .length;
  }

  static Future<int> userCount() async => _countOf('assets/seed/users.json');

  static Future<int> _countOf(String asset) async =>
      (await readJsonAsset(asset) as List<dynamic>).length;

  /// Reads a bundled JSON asset without `rootBundle.loadString`.
  ///
  /// Above 50 KB that method decodes in a background isolate, which never
  /// completes inside `testWidgets` — see `SeedLoader._readJson`. The seed is
  /// well over that now, so the tests have to read it the same way the app
  /// does.
  static Future<Object?> readJsonAsset(String asset) async {
    final bytes = await rootBundle.load(asset);
    return jsonDecode(
      utf8.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  }
}
