import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../features/jobs/job_filter_controller.dart';
import '../features/map/location_controller.dart';
import '../services/job_repository.dart';
import '../services/local_store.dart';
import '../services/media_store.dart';
import 'app_shell.dart';
import 'job_controller.dart';
import 'settings_controller.dart';

/// Application root — wires up the controllers and the themes.
class TrustHireApp extends StatelessWidget {
  const TrustHireApp({
    super.key,
    required this.store,
  });

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MediaStore>(create: (_) => MediaStore(store)),
        ChangeNotifierProvider(
          create: (_) => SettingsController(store)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => JobController(JobRepository(store, MediaStore(store)))
            ..load(),
        ),
        ChangeNotifierProvider(create: (_) => JobFilterController()),
        ChangeNotifierProvider(
          // Location is requested on first launch so the map can open on the
          // user rather than the fallback. A refusal is handled, not retried.
          create: (_) => LocationController()..request(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Trust Hire',
            debugShowCheckedModeBanner: false,
            theme: BrandTheme.light,
            darkTheme: BrandTheme.dark,
            themeMode: settings.themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
