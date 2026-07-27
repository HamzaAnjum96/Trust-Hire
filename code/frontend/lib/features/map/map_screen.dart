import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/tokens.dart';
import '../../widgets/state_views.dart';

/// The map — the primary surface of the product.
///
/// Sprint 0 stands this screen up with real data behind it so the seed →
/// local storage pipeline is verifiable; the map itself lands in Sprint 1.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JobController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby work'),
      ),
      body: switch (controller.state) {
        LoadState.idle || LoadState.loading =>
          const LoadingView(message: 'Loading nearby jobs…'),
        LoadState.failed => ErrorView(
            message: controller.errorMessage ??
                'Could not load jobs. Try again.',
            onRetry: controller.load,
          ),
        LoadState.ready => _MapPlaceholder(jobCount: controller.jobs.length),
      },
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.jobCount});

  final int jobCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      color: isLight ? BrandColours.warmSand : BrandColours.darkSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(BrandSizing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.place_outlined,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: BrandSizing.spaceMd),
              Text(
                '$jobCount jobs loaded',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              Text(
                'Seed data is in local storage. The map arrives in Sprint 1.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
