import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// One row of an inbox: Updates and Messages both use it.
///
/// **Flat on the page since 0.23**, like the job rows: a hairline under each
/// row but the last, no box around the list. It used to draw the whole list
/// as one bordered card a row at a time, which made the inbox the one list in
/// the app with a frame round it.
///
/// [highlighted] marks something new with a sand fill *and* a burgundy dot at
/// the leading edge. It used to be a 3px coloured bar, which was colour alone
/// doing the work; a dot is what every inbox people already use draws, and it
/// survives being glanced at in either theme.
class InboxRow extends StatelessWidget {
  const InboxRow({
    super.key,
    required this.index,
    required this.count,
    required this.child,
    this.highlighted = false,
  });

  /// Where this row sits, and how many there are.
  final int index;
  final int count;

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = index == count - 1;
    final fill = theme.brightness == Brightness.light
        ? BrandColours.warmSand
        : BrandColours.darkElevated;

    return Material(
      color: highlighted ? fill : Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Stack(
          children: [
            child,
            if (highlighted)
              PositionedDirectional(
                start: 5,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
