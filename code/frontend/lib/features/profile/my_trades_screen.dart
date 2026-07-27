import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/profile_controller.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job_tag.dart';
import '../../widgets/tag_tile.dart';

/// Where a worker says what they do.
///
/// The screen a worker never has to visit: everyone starts on general work and
/// sees jobs from the first launch. Adding a trade only widens the feed, and
/// the default cannot be switched off — which is why there is no "save" here,
/// and no way to leave with nothing selected.
class MyTradesScreen extends StatelessWidget {
  const MyTradesScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MyTradesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final profile = context.watch<ProfileController>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.myTrades)),
      body: ReadableWidth(
        // Wider than the reading measure: this is a grid of tiles, and more
        // columns means less scrolling to find your own trade.
        maxWidth: 900,
        child: ListView(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
          children: [
            Text(strings.myTradesHelp, style: theme.textTheme.bodyMedium),
            const SizedBox(height: BrandSizing.spaceSm),
            Text(
              strings.generalWorkAlwaysOn,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: BrandSizing.spaceLg),
            Wrap(
              spacing: BrandSizing.spaceSm,
              runSpacing: BrandSizing.spaceSm,
              children: [
                for (final tag in JobTag.values)
                  TagTile(
                    tag: tag,
                    selected: profile.tags.contains(tag),
                    // The default is shown selected and inert rather than
                    // hidden: a worker should be able to see that general work
                    // is on, not just be told it.
                    enabled: !JobTag.defaultWorkerTags.contains(tag),
                    onTap: () => profile.toggleTag(tag),
                  ),
              ],
            ),
            const SizedBox(height: BrandSizing.spaceLg),
            Text(
              strings.tradeCount(profile.specialities.length),
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
