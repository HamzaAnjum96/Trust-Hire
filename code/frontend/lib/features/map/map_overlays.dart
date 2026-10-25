import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_switcher.dart';

/// The things that float on top of the map.
///
/// Split out of `map_screen.dart`, which had grown past a thousand lines and
/// held both the map's behaviour and the chrome around it. Nothing here knows
/// about jobs, filters or location — they take what they draw as arguments —
/// so they can be read, and changed, without reading the screen.
///
/// The rules about *where* these sit are the interesting part, and they are
/// written down on [MapOverlayWidth]: two of the four bugs found at unusual
/// window shapes were overlays landing on top of each other.

/// The bar across the top of the map: who you are, where you are, how much
/// work is here.
class MapHeader extends StatelessWidget {
  const MapHeader({
    super.key,
    required this.jobCount,
    required this.totalJobCount,
  });

  final int jobCount;
  final int totalJobCount;

  /// Fixed, so the rows under it can be placed from it rather than from a
  /// number somebody has to keep in step by hand — which is how the filter
  /// chips came to sit 16px over the header's bottom edge.
  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Container(
      height: MapHeader.height,
      padding: const EdgeInsetsDirectional.only(
        start: BrandSizing.spaceXs,
        end: BrandSizing.spaceSm + 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BrandRadius.largeAll,
        boxShadow: BrandShadows.card,
      ),
      child: Row(
        children: [
          // The map has no app bar to hang the account switcher off, and the
          // landing screen is the one place a demonstration must not leave
          // "who am I?" unanswered. It takes the header's leading slot: the
          // heading beside it already says these are jobs near a place, so
          // the pin icon was saying it twice.
          Tooltip(
            message: strings.switchAccount,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => AccountSheet.open(context),
              // The avatar is drawn at 28px, but section 29 asks for a 48px
              // target and a circle is harder to hit than a rectangle. The
              // box is invisible; only the reach changes.
              child: SizedBox(
                width: BrandSizing.touchTargetPreferred,
                height: BrandSizing.touchTargetPreferred,
                child: Center(
                  child: AccountAvatar(
                    account: context.watch<AccountController>().active,
                    radius: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: BrandSizing.spaceXs),
          Expanded(
            child: Text(
              strings.nearbyWork,
              style: theme.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: BrandSizing.spaceSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSizing.spaceSm + 2,
              vertical: BrandSizing.spaceXs,
            ),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? BrandColours.warmSand
                  : BrandColours.darkElevated,
              borderRadius: BrandRadius.mediumAll,
            ),
            child: Text(
              // Say what is being hidden, so a short list never looks like a
              // bug.
              jobCount == totalJobCount
                  ? strings.jobCount(jobCount)
                  : strings.jobCountFiltered(jobCount, totalJobCount),
              style: BrandType.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caps a floating map overlay and pins it to the leading edge.
///
/// A notice stretched across a 1440px browser is a line of text with a metre
/// of white beside it, and the header's count ends up half a screen from its
/// title. Leading-aligned rather than centred so the header, the filters and
/// the notices read as one stack.
class MapOverlayWidth extends StatelessWidget {
  const MapOverlayWidth({
    super.key,
    required this.child,
    this.clearsMapControls = false,
  });

  final Widget child;

  /// Whether this overlay can grow far enough down the screen to reach the
  /// map's own buttons.
  ///
  /// True only for the notices. The header and the filter chips are a fixed
  /// two rows at the top and could never get near the bottom-right controls,
  /// so narrowing *them* would cost width to prevent a collision that cannot
  /// happen.
  final bool clearsMapControls;

  /// What the map's controls occupy on the right, plus the gap they need to
  /// read as separate from anything beside them.
  ///
  /// **The notices must never reach this.** On a phone held sideways the
  /// trades notice grew wide enough to sit underneath the fullscreen button —
  /// two tappable things in the same place, one of them invisible.
  static const controlGutter =
      BrandSizing.touchTargetPreferred + BrandSizing.spaceMd * 2;

  /// Below this, the notice column can reach the controls; above it, it
  /// cannot.
  ///
  /// The notices start about 128px down ([noticesTop]) and are capped at a
  /// third of the height; the controls sit about 200px up from the bottom.
  /// Those two meet when `128 + h/3 > h - 200`, which is a little under 492.
  /// Rounded up, and applied only there — on a tall phone the gutter would
  /// cost a quarter of the width of a narrow screen to avoid a collision that
  /// cannot happen, which is how the notice ended up one word per line at
  /// 320px.
  static const controlsAreInTheWayBelow = 500.0;

  /// Where the filter chips start, below the safe area: under the header,
  /// with a gap.
  static const chipsTop =
      BrandSizing.spaceSm + MapHeader.height + BrandSizing.spaceSm;

  /// Where the notices start, below the safe area: under the chips, with a
  /// gap.
  static const noticesTop =
      chipsTop + BrandSizing.touchTargetMinimum + BrandSizing.spaceSm + 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crowded =
            MediaQuery.sizeOf(context).height < controlsAreInTheWayBelow;
        final available =
            constraints.maxWidth -
            (clearsMapControls && crowded ? controlGutter : 0.0);

        return Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: available.clamp(0.0, BrandSizing.readableWidth),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// A card explaining something about the state of the map — no location, no
/// trades set, nothing matching the filters.
class MapNotice extends StatelessWidget {
  const MapNotice({
    super.key,
    required this.icon,
    required this.message,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onDismiss;

  /// An optional way out of whatever the notice describes. Dismissing is not
  /// always the right offer: nothing changes for a worker who closes the
  /// trades notice without adding one.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BrandSizing.spaceMd,
        BrandSizing.spaceSm + 4,
        BrandSizing.spaceXs,
        BrandSizing.spaceSm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BrandRadius.largeAll,
        border: Border.all(
          color: BrandColours.informationBlue.withValues(alpha: 0.35),
        ),
        boxShadow: BrandShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: BrandColours.informationBlue),
          ),
          const SizedBox(width: BrandSizing.spaceSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: BrandSizing.spaceXs),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // A link under the words rather than a full-width button
                // under them: on a phone the trades notice, button and all,
                // covered the top third of the map it was explaining.
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              tooltip: strings.dismiss,
              // Not `VisualDensity.compact`, which takes the target to 40px.
              // Section 29 asks for 48, and this is the control somebody
              // reaches for when a notice is in the way of the map — the
              // worst one to make hard to hit.
              constraints: const BoxConstraints(
                minWidth: BrandSizing.touchTargetPreferred,
                minHeight: BrandSizing.touchTargetPreferred,
              ),
            ),
        ],
      ),
    );
  }
}

/// A square control floating over the map.
///
/// **This was two widgets** — one for "show all jobs", one for "near me" —
/// identical but for what went in the middle, which is why only one of them
/// ever got the shadow colour right. The spinner is the only real difference,
/// and it is a flag rather than a class.
class MapButton extends StatelessWidget {
  const MapButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
  });

  final IconData icon;

  /// Read out instead of the icon. These controls have no visible text, so
  /// without this they are announced as nothing at all.
  final String label;

  /// Null disables the control — "show all jobs" with no jobs to show.
  final VoidCallback? onPressed;

  /// Swaps the icon for a spinner and stops it responding, for a control
  /// whose work takes long enough to notice. Asking the browser for a
  /// location does.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !isBusy;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BrandRadius.mediumAll,
      elevation: 2,
      shadowColor: BrandColours.ink.withValues(alpha: 0.2),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BrandRadius.mediumAll,
        child: SizedBox(
          width: BrandSizing.touchTargetPreferred,
          height: BrandSizing.touchTargetPreferred,
          child: isBusy
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(
                  icon,
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  semanticLabel: label,
                ),
        ),
      ),
    );
  }
}
