import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../map/location_controller.dart';

/// The first run.
///
/// Three screens, all skippable. It exists for two reasons:
///
/// 1. The product's central idea — that you post work by *speaking* rather
///    than filling in a form — is unusual enough that an audience used to
///    forms will not discover it by poking around.
/// 2. The app used to ask for location on launch with no explanation, which
///    is precisely what section 19 warns against. Location is now requested
///    only after saying what it is for and that refusing is fine.
///
/// No illustrations: section 17 allows them for onboarding, but a placeholder
/// illustration would be worse than the brand's own iconography used plainly.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.location,
    required this.onFinished,
  });

  final LocationController location;

  /// Called when the user finishes or skips. The caller records that the
  /// intro has been seen.
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;
  bool _requesting = false;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      widget.onFinished();
      return;
    }
    _pages.nextPage(
      duration: Motion.standard(context),
      curve: BrandMotion.curve,
    );
  }

  Future<void> _askForLocation() async {
    setState(() => _requesting = true);
    // A refusal is fine — the controller already treats it as a normal state,
    // so there is nothing to handle here beyond moving on.
    await widget.location.request();
    if (!mounted) return;

    setState(() => _requesting = false);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight
          ? BrandColours.warmSand
          : BrandColours.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(BrandSizing.spaceSm),
                child: TextButton(
                  onPressed: widget.onFinished,
                  child: Text(strings.onboardSkip),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _Panel(
                    icon: Icons.place_outlined,
                    title: strings.onboardWelcomeTitle,
                    body: strings.onboardWelcomeBody,
                  ),
                  _Panel(
                    icon: Icons.mic_none,
                    title: strings.onboardVoiceTitle,
                    body: strings.onboardVoiceBody,
                  ),
                  _Panel(
                    icon: Icons.near_me_outlined,
                    title: strings.onboardLocationTitle,
                    body: strings.onboardLocationBody,
                    footnote: strings.onboardPrivacyNote,
                  ),
                ],
              ),
            ),

            _Dots(count: _pageCount, current: _page),
            const SizedBox(height: BrandSizing.spaceLg),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                BrandSizing.spaceLg,
                0,
                BrandSizing.spaceLg,
                BrandSizing.spaceLg,
              ),
              child: _page == _pageCount - 1
                  // The last panel is the only place location is asked for,
                  // and only after saying what it is for.
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _requesting ? null : _askForLocation,
                            child: _requesting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: BrandColours.white,
                                    ),
                                  )
                                : Text(strings.onboardAllowLocation),
                          ),
                        ),
                        const SizedBox(height: BrandSizing.spaceSm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _requesting ? null : widget.onFinished,
                            child: Text(strings.onboardNotNow),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(strings.onboardNext),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.body,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? footnote;

  /// Below this the panel is drawn small. The same number `LayoutSize` uses to
  /// decide a window is too short for a navigation rail — a window that cannot
  /// hold a rail cannot hold a 96px medallion above a display-sized heading
  /// either.
  static const _shortWindow = 520.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // **A phone held sideways has about 380px, and the full-size panel needs
    // more than that before it reaches the body text.** It scrolls, so nothing
    // overflows and nothing failed — but the first thing a new user reads was
    // below the fold with no hint that there was a fold, which is the same
    // defect as the navigation rail that hid Profile.
    //
    // So the decoration gives way rather than the words: a smaller medallion
    // and tighter gaps, and the sentence fits.
    final isShort = MediaQuery.sizeOf(context).height < _shortWindow;
    final medallion = isShort ? 56.0 : 96.0;
    final gap = isShort ? BrandSizing.spaceMd : BrandSizing.spaceXl;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: BrandSizing.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: gap),
          Container(
            width: medallion,
            height: medallion,
            decoration: BoxDecoration(
              color: isLight ? BrandColours.white : BrandColours.darkSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: isShort ? 28 : 44,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: gap),
          Text(
            title,
            style: isShort
                ? theme.textTheme.headlineSmall
                : theme.textTheme.displayMedium,
          ),
          const SizedBox(height: BrandSizing.spaceMd),
          Text(body, style: theme.textTheme.bodyLarge),
          if (footnote != null) ...[
            const SizedBox(height: BrandSizing.spaceLg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: BrandColours.informationBlue,
                ),
                const SizedBox(width: BrandSizing.spaceSm),
                Expanded(
                  child: Text(footnote!, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Semantics(
      label: strings.onboardStepOf(current + 1, count),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: Motion.fast(context),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
