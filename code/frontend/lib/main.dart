import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage is opened before the first frame so the app never renders
  // against an uninitialised store.
  final store = await LocalStore.open();

  runApp(TrustHireApp(store: store));
}
