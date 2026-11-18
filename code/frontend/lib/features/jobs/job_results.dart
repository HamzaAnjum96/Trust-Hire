import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../models/job.dart';
import '../../services/media_store.dart';
import '../../widgets/state_views.dart';
import 'job_details_sheet.dart';
import 'job_filter_controller.dart';
import 'job_row.dart';
import '../profile/my_trades_screen.dart';
import '../../l10n/app_localizations.dart';

/// The jobs as a list: the second view of the Jobs destination.
///
/// Until 0.23 this was a destination of its own, "Find work", beside "Map" —
/// the same jobs under the same filters, one tap apart in the navigation bar.
/// It is now what the map turns into when the view switch is pressed, under
/// the same search bar, so switching never loses a query or a filter.
///
/// Results, or an empty state that distinguishes "nothing posted" from
/// "nothing matches" — they need different next steps.
class JobResults extends StatelessWidget {
  const JobResults({
    super.key,
    required this.all,
    required this.reachable,
    required this.visible,
    required this.filters,
    required this.viewerLocation,
    this.header,
    this.bottomPadding = BrandSizing.spaceXl,
  });

  final List<Job> all;

  /// Everything the visibility rule allows, before the user's own filters.
  final List<Job> reachable;

  final List<Job> visible;
  final JobFilterController filters;
  final JobLocation? viewerLocation;

  /// Room under the last row for whatever floats over the bottom of the list.
  final double bottomPadding;

  /// Scrolls with the rows, above them: the trade board on Jobs.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (all.isEmpty) {
      return EmptyView(
        icon: Icons.work_outline_rounded,
        title: strings.noJobsYet,
        message: strings.postTheFirstJob,
      );
    }

    // Three empty states, because they need three different next steps.
    // Clearing filters cannot bring back a job the tag rule excluded, so
    // offering that button here would be a dead end.
    if (reachable.isEmpty) {
      return EmptyView(
        icon: Icons.construction_rounded,
        title: strings.noJobsForTrades,
        message: strings.noJobsForTradesHelp,
        action: OutlinedButton(
          onPressed: () => MyTradesScreen.open(context),
          child: Text(strings.addATrade),
        ),
      );
    }

    if (visible.isEmpty) {
      final empty = EmptyView(
        icon: Icons.search_off_rounded,
        title: strings.noJobsMatch,
        message: strings.tryWiderArea,
        action: OutlinedButton(
          onPressed: filters.clear,
          child: Text(strings.clearFilters),
        ),
      );
      // The board stays, so the way back to every trade is still on screen.
      if (header == null) return empty;
      return ListView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        children: [header!, empty],
      );
    }

    final now = DateTime.now();

    final head = header;
    final offset = head == null ? 0 : 1;

    return ListView.separated(
      padding: EdgeInsets.only(top: BrandSizing.spaceXs, bottom: bottomPadding),
      itemCount: visible.length + offset,
      separatorBuilder: (_, index) => head != null && index == 0
          ? const Divider(height: 1)
          : const Divider(indent: BrandSizing.spaceMd),
      itemBuilder: (context, i) {
        if (head != null && i == 0) return head;
        final index = i - offset;
        // No entrance stagger since 0.26: it replayed every time a filter or
        // the trade board narrowed the list, making people wait to read the
        // list they had just asked for.
        return JobRow(
          job: visible[index],
          now: now,
          viewerLocation: viewerLocation,
          onTap: () => JobDetailsSheet.open(
            context,
            jobId: visible[index].id,
            mediaStore: context.read<MediaStore>(),
            viewerLocation: viewerLocation,
          ),
        );
      },
    );
  }
}
