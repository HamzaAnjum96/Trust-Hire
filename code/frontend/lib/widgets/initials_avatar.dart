import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// A round avatar with somebody's initials, in neutral colours.
///
/// For people in the directory, who are not demo accounts and so have no
/// `AccountAvatar`. Neutral on purpose — sand and ink, never burgundy or
/// copper: Section 9 sells *visibility*, and a listing that looked marked out
/// by the brand's own colours would look endorsed.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  /// The first letter of the first two words: "Sadia Iqbal" → "SI".
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words
        .take(2)
        .map((word) => String.fromCharCodes(word.runes.take(1)))
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return CircleAvatar(
      radius: radius,
      backgroundColor: isLight
          ? BrandColours.warmSand
          : BrandColours.darkElevated,
      child: Text(
        initialsOf(name),
        style: BrandType.button.copyWith(
          fontSize: radius * 0.7,
          height: 1,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
