import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';
import '../../widgets/state_views.dart';

/// A plain list of every job in local storage.
///
/// The map is the product, so this is a secondary view — but it proves the
/// data pipeline end to end and gives a keyboard-free way to reach a job.
class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JobController>();

    return Scaffold(
      appBar: AppBar(title: const Text('All jobs')),
      body: switch (controller.state) {
        LoadState.idle || LoadState.loading =>
          const LoadingView(message: 'Loading jobs…'),
        LoadState.failed => ErrorView(
            message:
                controller.errorMessage ?? 'Could not load jobs. Try again.',
            onRetry: controller.load,
          ),
        LoadState.ready => controller.jobs.isEmpty
            ? const EmptyView(
                icon: Icons.work_outline,
                title: 'No jobs yet',
                message: 'Post the first job to see it here.',
              )
            : _JobList(jobs: controller.jobs),
      },
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        // Clear the floating action button.
        BrandSizing.spaceXl * 3,
      ),
      itemCount: jobs.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: BrandSizing.spaceSm + 4),
      itemBuilder: (context, index) => _JobRow(job: jobs[index], now: now),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.now});

  final Job job;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.displayTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (job.isLocal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BrandSizing.spaceSm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColours.copper,
                      borderRadius: BrandRadius.smallAll,
                    ),
                    child: const Text(
                      'On this device',
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        color: BrandColours.white,
                      ),
                    ),
                  ),
              ],
            ),
            if (job.supportingDescription != null) ...[
              const SizedBox(height: BrandSizing.spaceXs),
              Text(
                job.supportingDescription!,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: BrandSizing.spaceSm + 4),
            Wrap(
              spacing: BrandSizing.spaceMd,
              runSpacing: BrandSizing.spaceXs,
              children: [
                _Meta(
                  icon: Icons.schedule,
                  label: Format.scheduled(job.scheduledTime, now),
                ),
                if (job.hasVoiceNote)
                  const _Meta(icon: Icons.mic, label: 'Voice note'),
                if (job.hasPhotos)
                  _Meta(
                    icon: Icons.photo_library_outlined,
                    label: '${job.photoPaths.length} photo'
                        '${job.photoPaths.length == 1 ? '' : 's'}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: BrandSizing.spaceXs + 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
