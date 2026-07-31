import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// One small fact about a job: when it is, how far away, how big the area.
///
/// **This was two widgets** — `_Meta` in the job row and `_MetaChip` in the
/// map's preview card — drawing the same icon-and-label pair from the same
/// tokens. They were not quite the same, and the difference was the bug: only
/// the job row's copy capped its width, so only the job row's copy survived a
/// long Pakistani area name.
class MetaChip extends StatelessWidget {
  const MetaChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  /// Wide enough for "Ghulam Muhammad Abad, Faisalabad" to be worth reading,
  /// narrow enough that two of them still fit on a 320px line.
  static const maxWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Capped and ellipsised rather than free to size itself. A Wrap gives a
    // child the full line width and lets it overflow past that, and a long
    // area name in the 380px results rail is wider than the line — which
    // paints the yellow-and-black overflow stripes over a job row.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: BrandSizing.spaceXs + 2),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
