import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// A titled group of rows on one surface, divided by hairlines.
///
/// The profile used to be a column of headings, paragraphs and tiles laid
/// straight on the page, so twenty things competed at the same weight and the
/// eye had no way to tell where one subject ended. A group puts the rows that
/// belong together on one card, which makes the page five things instead.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    this.title,
    this.caption,
    required this.children,
  });

  final String? title;

  /// A line under the card — what the group is for, when that is not obvious.
  final String? caption;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: BrandSizing.spaceXs,
              bottom: BrandSizing.spaceSm,
            ),
            child: Text(title!, style: theme.textTheme.titleMedium),
          ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) const Divider(indent: BrandSizing.spaceMd),
                child,
              ],
            ],
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              BrandSizing.spaceXs,
              BrandSizing.spaceSm,
              BrandSizing.spaceXs,
              0,
            ),
            child: Text(caption!, style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }
}

/// Padding for something in a [SettingsGroup] that is not a list tile — a
/// control with a label above it, a paragraph, a record.
class GroupPadding extends StatelessWidget {
  const GroupPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(BrandSizing.spaceMd),
    child: child,
  );
}
