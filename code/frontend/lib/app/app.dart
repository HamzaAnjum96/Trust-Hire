import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/job_repository.dart';
import '../services/local_store.dart';
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
        ChangeNotifierProvider(
          create: (_) => SettingsController(store)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => JobController(JobRepository(store))..load(),
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
