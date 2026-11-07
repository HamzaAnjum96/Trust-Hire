import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// The box a search field sits in, with room for actions at its end.
///
/// One look for every search in the app — Jobs (over the map and above the
/// list) and the Directory — so somebody who has learned where "Ask" is in
/// one knows where it is in the other. The field inside draws no box of its
/// own; this is the box.
class SearchBarFrame extends StatelessWidget {
  const SearchBarFrame({
    super.key,
    required this.field,
    this.trailing = const [],
    this.floating = false,
  });

  final Widget field;

  /// After a hairline: Ask, and on Jobs the account avatar.
  final List<Widget> trailing;

  /// Over the map it needs a shadow to read as something on top of it; on
  /// the page it takes a hairline instead.
  final bool floating;

  static const height = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BrandRadius.mediumAll,
        border: floating
            ? null
            : Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: floating ? BrandShadows.card : null,
      ),
      child: Row(
        children: [
          Expanded(child: field),
          if (trailing.isNotEmpty) ...[
            SizedBox(
              height: 24,
              child: VerticalDivider(
                width: 1,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            ...trailing,
            const SizedBox(width: BrandSizing.spaceXs),
          ],
        ],
      ),
    );
  }
}

/// The decoration for a field inside a [SearchBarFrame]: no box, no fill.
InputDecoration searchBarDecoration({
  required String hint,
  Widget? suffixIcon,
}) => InputDecoration(
  hintText: hint,
  prefixIcon: const Icon(Icons.search),
  suffixIcon: suffixIcon,
  filled: false,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  contentPadding: const EdgeInsets.symmetric(vertical: BrandSizing.spaceSm + 6),
);
