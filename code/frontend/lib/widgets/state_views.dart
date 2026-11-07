import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Shared loading, empty and error views.
///
/// Section 19 of the brand guidelines asks for copy that tells the user what
/// they can do next, so every one of these takes a plain-language message and
/// the error view always offers a way forward.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: BrandSizing.spaceMd),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// An empty state: what is missing, and the next step.
///
/// Since 0.23 without the 88px sand medallion it used to lead with. Every
/// empty tab in the app opened on the same large circle, which made "nothing
/// yet" the loudest thing on the screen. The icon is now a quiet marker, and
/// the words — and the button, when there is one — carry it.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // **Scrollable, not just centred.** An empty state is the one thing on the
    // screen, so a fixed column that is four pixels too tall has nowhere to
    // put them — which is what happened on a phone held sideways, where the
    // app bar, the tabs and the navigation bar leave about 210px. Centred
    // while it fits, scrolled when it does not.
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.25,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSizing.spaceLg,
              vertical: BrandSizing.spaceXl,
            ),
            child: ConstrainedBox(
              // A message wider than this is read as a paragraph rather than
              // as a line of advice.
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: BrandSizing.spaceMd),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: BrandSizing.spaceSm),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (action != null) ...[
                    const SizedBox(height: BrandSizing.spaceLg),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An error state. Always names a recovery step — never a raw exception.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BrandSizing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: BrandColours.errorRed,
            ),
            const SizedBox(height: BrandSizing.spaceMd),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: BrandSizing.spaceLg),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A soft informational panel — used for the local-storage notice and
/// permission explanations. Information Blue, never alarming.
class NoticePanel extends StatelessWidget {
  const NoticePanel({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = NoticeTone.information,
  });

  final String message;
  final IconData icon;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = switch (tone) {
      NoticeTone.information => BrandColours.informationBlue,
      NoticeTone.warning => BrandColours.warningAmber,
      NoticeTone.success => BrandColours.successTeal,
    };

    return Container(
      padding: const EdgeInsets.all(BrandSizing.spaceMd),
      decoration: BoxDecoration(
        // A 10% tint of the tone colour keeps the panel calm.
        color: colour.withValues(alpha: 0.10),
        borderRadius: BrandRadius.mediumAll,
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amber fails contrast as text on light surfaces, so the tone is
          // carried by the icon and border while the message stays in Ink.
          Icon(icon, size: 20, color: colour),
          const SizedBox(width: BrandSizing.spaceSm + 4),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum NoticeTone { information, warning, success }
