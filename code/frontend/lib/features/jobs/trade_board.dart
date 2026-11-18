import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/roles.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../models/job_tag.dart';
import '../../widgets/focus_ring.dart';

/// One trade's line on the board: how many jobs, how close the nearest, what
/// they pay.
class TradeLine {
  TradeLine(this.tag);

  final JobTag tag;
  int count = 0;

  /// Metres to the closest of them, when the viewer's position is known.
  double? nearest;

  /// The lowest and highest fare among those that carry one.
  int? low;
  int? high;
}

/// **Work near you, by trade: the Jobs destination's index, since 0.26.**
///
/// The owner found 0.24 only a refont and recolour, and Impeccable's surface
/// round dealt a trade hub to lead (documents/design/2026-11-18-structure.md).
/// A grid of same-size tiles is the category's default, so it is a board
/// instead: one row per trade near you, columns that never move, read down
/// like a departures board. What a worker reads first is work: how much of
/// it, how close, what it pays.
///
/// Tapping a trade shows only its jobs, in the list under the board and on
/// the map, and its row glows turmeric, the colour of what is selected.
/// Tapping it again shows every trade.
///
/// Counted from the jobs under every other filter, so "Today's jobs" or
/// "Near me" change the numbers here too. A job with two trades is counted
/// under both.
class TradeBoard extends StatefulWidget {
  const TradeBoard({
    super.key,
    required this.jobs,
    required this.viewerLocation,
    required this.selected,
    required this.onSelect,
    this.hiddenJobs = 0,
    this.onAddTrade,
  });

  final List<Job> jobs;
  final JobLocation? viewerLocation;
  final Set<JobTag> selected;
  final ValueChanged<JobTag> onSelect;

  /// Jobs near the viewer that none of their trades reach: non-zero only for
  /// a worker who has not added one. The board ends with an "Add a trade"
  /// row that says how many, since 0.30; before, a notice floated over the
  /// map to say it, covering the thing the app is for.
  final int hiddenJobs;
  final VoidCallback? onAddTrade;

  /// The board's rows: busiest trade first, then in the trades' own order.
  static List<TradeLine> linesFor(List<Job> jobs, JobLocation? viewer) {
    final byTag = <JobTag, TradeLine>{};
    for (final job in jobs) {
      final fare = job.agreedFare ?? job.startingFare;
      final metres = viewer == null ? null : job.location.distanceTo(viewer);
      for (final tag in job.tags) {
        final line = byTag.putIfAbsent(tag, () => TradeLine(tag));
        line.count++;
        if (metres != null &&
            (line.nearest == null || metres < line.nearest!)) {
          line.nearest = metres;
        }
        if (fare != null) {
          if (line.low == null || fare < line.low!) line.low = fare;
          if (line.high == null || fare > line.high!) line.high = fare;
        }
      }
    }
    return byTag.values.toList()..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.tag.index.compareTo(b.tag.index);
    });
  }

  /// How many trades the board shows before "Show all": enough for the
  /// busiest work, few enough that the jobs under it stay in view.
  static const shortLength = 5;

  @override
  State<TradeBoard> createState() => _TradeBoardState();
}

class _TradeBoardState extends State<TradeBoard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final selected = widget.selected;
    final all = TradeBoard.linesFor(widget.jobs, widget.viewerLocation);
    final addTrade = widget.hiddenJobs > 0 && widget.onAddTrade != null;
    if (all.isEmpty && !addTrade) return const SizedBox.shrink();

    // The busiest few, and the chosen trade wherever it ranks: a choice that
    // scrolled off the board would look like no choice at all.
    final long = all.length > TradeBoard.shortLength + 1;
    final lines = !long || _showAll
        ? all
        : [
            for (final (i, line) in all.indexed)
              if (i < TradeBoard.shortLength || selected.contains(line.tag))
                line,
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colours.surface,
        borderRadius: BrandRadius.largeAll,
        boxShadow: context.colours.card,
      ),
      child: ClipRRect(
        borderRadius: BrandRadius.largeAll,
        // Below about 350px of board there is no room for a fares column
        // beside a trade's name; the fares move under the name instead, so a
        // name is never squeezed to one word a line. A phone's board is about
        // 358px; the rail beside a desktop map, 348, where "General work"
        // broke over two lines at 340.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 350;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BoardHeader(wide: wide),
                const Divider(height: 1),
                for (final (i, line) in lines.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 68),
                  _TradeRow(
                    line: line,
                    wide: wide,
                    isSelected:
                        selected.length == 1 && selected.contains(line.tag),
                    onTap: () => widget.onSelect(line.tag),
                  ),
                ],
                if (addTrade) ...[
                  if (lines.isNotEmpty) const Divider(height: 1, indent: 68),
                  _AddTradeRow(
                    hiddenJobs: widget.hiddenJobs,
                    onTap: widget.onAddTrade!,
                  ),
                ],
                if (long) ...[
                  const Divider(height: 1),
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll
                          ? strings.boardShowFewer
                          : strings.boardShowAll(all.length),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The column labels, so the board reads as a table: what each column is
/// is said once, not on every row.
class _BoardHeader extends StatelessWidget {
  const _BoardHeader({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: context.colours.textMuted);

    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          BrandSizing.spaceSm + 2,
          BrandSizing.spaceMd,
          BrandSizing.spaceSm,
        ),
        child: Row(
          children: [
            Expanded(child: Text(strings.boardTrade, style: style)),
            SizedBox(
              width: _TradeRow.countWidth,
              child: Text(
                strings.boardJobs,
                style: style,
                textAlign: TextAlign.end,
              ),
            ),
            if (wide) ...[
              const SizedBox(width: BrandSizing.spaceMd),
              SizedBox(
                width: _TradeRow.faresWidth,
                child: Text(
                  strings.boardFares,
                  style: style,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({
    required this.line,
    required this.wide,
    required this.isSelected,
    required this.onTap,
  });

  final TradeLine line;
  final bool wide;
  final bool isSelected;
  final VoidCallback onTap;

  static const countWidth = 44.0;
  static const faresWidth = 112.0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colours = context.colours;

    final trade = line.tag.label(strings);
    final nearest = line.nearest == null
        ? null
        : strings.nearestAt(Format.span(strings, line.nearest!));
    final fares = line.low == null
        ? strings.fareOpenToOffers
        : Format.fareRange(strings, line.low!, line.high!);

    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colours.textMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // Said as one sentence: "Plumbing, 4 jobs, nearest 1.2 km, Rs. 1,500–
    // 7,000", not four cells read one at a time.
    final spoken = [
      trade,
      strings.jobCount(line.count),
      ?nearest,
      fares,
    ].join(', ');

    // A node of its own: without `container`, a board of one row merged
    // into the heading above it, and a screen reader read "Work near you"
    // and the hint as part of the button.
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: spoken,
      // The InkWell's own action is excluded with its text, so the row
      // carries the tap itself: a screen reader activates the row, not a
      // point on it.
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? colours.selection : Colors.transparent,
        child: FocusRing(
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: BrandSizing.touchTargetPreferred + 16,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BrandSizing.spaceMd,
                  vertical: BrandSizing.spaceSm + 4,
                ),
                child: Row(
                  children: [
                    // The trade's glyph in a 40px block: turmeric under ink
                    // when chosen, the neutral tint at rest.
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? colours.highlight : colours.tint,
                        borderRadius: BrandRadius.mediumAll,
                      ),
                      child: Icon(
                        line.tag.icon,
                        size: 22,
                        color: isSelected ? colours.onHighlight : colours.text,
                      ),
                    ),
                    const SizedBox(width: BrandSizing.spaceSm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trade,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? colours.accentText : null,
                            ),
                          ),
                          if (nearest != null || !wide)
                            Text(
                              [?nearest, if (!wide) fares].join(' · '),
                              style: muted,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: countWidth,
                      child: Text(
                        '${line.count}',
                        textAlign: TextAlign.end,
                        style: theme.fareStyle,
                      ),
                    ),
                    if (wide) ...[
                      const SizedBox(width: BrandSizing.spaceMd),
                      SizedBox(
                        width: faresWidth,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(fares, style: muted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The board's last row, for a worker whose trades leave jobs out: what a
/// trade would add, and the way to add one. A row of the board rather than a
/// notice over it, so it never covers the work it is about.
class _AddTradeRow extends StatelessWidget {
  const _AddTradeRow({required this.hiddenJobs, required this.onTap});

  final int hiddenJobs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colours = context.colours;
    final more = strings.boardHiddenJobs(hiddenJobs);

    return Semantics(
      container: true,
      button: true,
      label: '${strings.addATrade}, $more',
      onTap: onTap,
      excludeSemantics: true,
      child: FocusRing(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSizing.spaceMd,
              vertical: BrandSizing.spaceSm + 4,
            ),
            child: Row(
              children: [
                // An empty block where a trade's glyph would be: the place
                // the next trade goes.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: colours.lineStrong),
                    borderRadius: BrandRadius.mediumAll,
                  ),
                  child: Icon(Icons.add_rounded, size: 22, color: colours.text),
                ),
                const SizedBox(width: BrandSizing.spaceSm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.addATrade,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colours.accentText,
                        ),
                      ),
                      Text(
                        more,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colours.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colours.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
