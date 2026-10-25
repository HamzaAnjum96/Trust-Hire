import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
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
/// Section 17 allows illustration here, and the first version declined it:
/// a placeholder illustration would be worse than the brand's own iconography
/// used plainly. On a tall enough window each panel now has a picture — but
/// drawn from the app's own pieces (a pin, a fare, a voice note, the circle a
/// job covers), so it shows what the next screen will, rather than decorating.
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
                    picture: const _MapPicture(),
                    title: strings.onboardWelcomeTitle,
                    body: strings.onboardWelcomeBody,
                  ),
                  _Panel(
                    icon: Icons.mic_none,
                    picture: const _VoicePicture(),
                    title: strings.onboardVoiceTitle,
                    body: strings.onboardVoiceBody,
                  ),
                  _Panel(
                    icon: Icons.near_me_outlined,
                    picture: const _LocationPicture(),
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
    required this.picture,
    required this.title,
    required this.body,
    this.footnote,
  });

  final IconData icon;

  /// Shown instead of the icon's medallion where there is room for it.
  final Widget picture;
  final String title;
  final String body;
  final String? footnote;

  /// Below this the panel is drawn small. The same number `LayoutSize` uses to
  /// decide a window is too short for a navigation rail — a window that cannot
  /// hold a rail cannot hold a 96px medallion above a display-sized heading
  /// either.
  static const _shortWindow = 520.0;

  /// From here up the panel has room for a picture instead of a medallion
  /// without pushing the sentence under it towards the dots and the button.
  /// `surfaces_test.dart` measures exactly that, at 320×720 among others.
  static const _pictureWindow = 700.0;

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
    final hasRoomForPicture =
        MediaQuery.sizeOf(context).height >= _pictureWindow;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: BrandSizing.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: gap),
          if (hasRoomForPicture)
            picture
          else
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

/// The surface each picture is drawn on: section 17's simple geometric forms
/// and rounded edges, in sand, burgundy, copper and ink — no glass, no
/// gradient, no sparkle.
class _PictureFrame extends StatelessWidget {
  const _PictureFrame({required this.child});

  final Widget child;

  static const height = 160.0;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isLight ? BrandColours.white : BrandColours.darkSurface,
        borderRadius: BrandRadius.sheetAll,
      ),
      // A picture of the product, not part of it: nothing here is announced
      // or can be tapped.
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Work on a map: a few streets, three pins, and one fare.
class _MapPicture extends StatelessWidget {
  const _MapPicture();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    // Deep Burgundy disappears on the dark surface; the dark theme's own
    // burgundy does not.
    final pin = isLight
        ? BrandColours.trustBurgundy
        : BrandColours.darkBurgundy;
    final chosen = isLight
        ? BrandColours.deepBurgundy
        : BrandColours.darkBurgundy;

    return _PictureFrame(
      child: CustomPaint(
        painter: _StreetsPainter(
          colour: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
        ),
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(-0.65, 0.45),
              child: _Pin(colour: pin),
            ),
            Align(
              alignment: const Alignment(0.7, 0.6),
              child: _Pin(colour: pin),
            ),
            Align(
              alignment: const Alignment(0.05, -0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BrandSizing.spaceSm + 2,
                      vertical: BrandSizing.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BrandRadius.smallAll,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Text(
                      Format.fare(strings, 2500),
                      style: theme.fareStyle.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Pin(colour: chosen, size: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.colour, this.size = 36});

  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.place, size: size, color: colour);
}

/// Three roads, drawn wide and soft so they read as a map and not as a chart.
class _StreetsPainter extends CustomPainter {
  const _StreetsPainter({required this.colour});

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    canvas
      ..drawPath(
        Path()
          ..moveTo(-20, h * 0.62)
          ..quadraticBezierTo(w * 0.45, h * 0.48, w + 20, h * 0.7),
        road,
      )
      ..drawLine(Offset(w * 0.3, -20), Offset(w * 0.38, h + 20), road)
      ..drawLine(Offset(w * 0.62, h + 20), Offset(w * 0.9, -20), road);
  }

  @override
  bool shouldRepaint(_StreetsPainter oldDelegate) =>
      oldDelegate.colour != colour;
}

/// A voice note: the copper button and the shape of somebody speaking.
class _VoicePicture extends StatelessWidget {
  const _VoicePicture();

  /// Fixed, so the picture is the same every time it is drawn.
  static const _bars = <double>[
    10,
    18,
    28,
    16,
    34,
    44,
    26,
    38,
    22,
    12,
    30,
    42,
    24,
    14,
    20,
    32,
    18,
    10,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return _PictureFrame(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
          decoration: BoxDecoration(
            color: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
            borderRadius: BrandRadius.largeAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isLight
                      ? BrandColours.copper
                      : BrandColours.darkCopper,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  color: BrandColours.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: BrandSizing.spaceMd),
              for (final height in _bars) ...[
                Container(
                  width: 4,
                  height: height,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Where you are, and the circle a job covers — which is all the app uses
/// your location for.
class _LocationPicture extends StatelessWidget {
  const _LocationPicture();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return _PictureFrame(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The area a job covers, as the map draws it.
          SizedBox(
            width: 128,
            height: 128,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BrandColours.jobRadiusFill,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: BrandColours.jobRadiusBorder, width: 1.5),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.18, -0.15),
            child: _Pin(
              colour: isLight
                  ? BrandColours.trustBurgundy
                  : BrandColours.darkBurgundy,
            ),
          ),
          // You, as the map draws you: Information Blue, never green.
          Align(
            alignment: Alignment(-0.3, 0.45),
            child: SizedBox(
              width: 40,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BrandColours.userLocationRing,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: BrandColours.userLocation,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: BrandColours.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
