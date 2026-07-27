import 'package:flutter/foundation.dart';

import '../services/job_repository.dart';
import '../services/local_store.dart';
import '../services/media_store.dart';

/// Everything that has to be true before the first frame.
///
/// Its own function, called by `main()` **and** by the tests that pump the
/// whole app, because the ordering it guarantees is the kind that only breaks
/// in production.
///
/// Seeding used to happen inside `JobController.load()`. That was fine while
/// the only seeded keys were the ones that controller read back itself; it
/// stopped being fine when the seed grew offers, ratings and wallets. Four
/// other controllers read their keys the moment they are constructed and raced
/// the write — the symptom being a worker with seventeen offers behind him
/// whose "Offers" tab said zero, on some launches and not others.
///
/// A test that builds the app without this is testing a different app.
Future<LocalStore> bootstrap() async {
  final store = await LocalStore.open();

  // Swallowed on purpose. Every repository reseeds on an empty read, so a
  // failed first run costs a slower second one rather than a blank app.
  try {
    await JobRepository(store, MediaStore(store)).ensureSeeded();
  } catch (error) {
    if (kDebugMode) debugPrint('Seeding failed, will retry on load: $error');
  }

  return store;
}
