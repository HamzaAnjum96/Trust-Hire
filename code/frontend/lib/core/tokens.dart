import 'package:flutter/material.dart';

/// Design tokens from `documents/brand-guidelines/brand-guidelines.md`, v0.2.
///
/// The palette, radii, spacing, type and motion, written down once. Screens do
/// not read [BrandColours] directly: they ask for a role from `AppColours` in
/// `roles.dart`, which maps these onto jobs (page, action, voice, the map).
/// `test/design_rules_test.dart` enforces that.
///
/// **0.24: ink and turmeric on lime-wash.** The colours of a working street —
/// lime-washed walls, lettering in near-black ink, turmeric for the one thing
/// that matters now — used with the discipline of something read in bright
/// sun. The reasoning is in `documents/design/2026-11-17-reskin-direction.md`.
class BrandColours {
  const BrandColours._();

  // --- Light ---------------------------------------------------------------

  /// The page: a cool lime-wash white. Not cream.
  static const limeWash = Color(0xFFF3F5F7);
  static const white = Color(0xFFFFFFFF);

  /// Hairlines between rows, round cards.
  static const line = Color(0xFFDCE1E6);

  /// Input borders and anything a line must be seen against: 3.6:1 on white.
  static const lineStrong = Color(0xFF7D8893);

  /// A quiet filled area: chips, tiles, a pill at rest.
  static const mist = Color(0xFFE7EBEF);

  /// Text, and every filled action in light mode: 15:1 on the page.
  static const ink = Color(0xFF16202A);

  /// Secondary text: 5.8:1 on the page.
  static const inkMuted = Color(0xFF56616C);

  /// The signature: what is selected, new or waiting. Never text on white
  /// (1.8:1); always carries ink on top of it (8.2:1).
  static const turmeric = Color(0xFFF2A900);

  /// A selected row's fill, quieter than [turmeric].
  static const turmericWash = Color(0xFFFFF0C2);

  /// Turmeric as words, for what is selected or waiting (a selected tab, an
  /// offer waiting, a warning): 6.3:1 on white. Never a general link colour;
  /// links and text buttons are ink.
  static const turmericText = Color(0xFF8A5300);

  /// Voice notes and nothing else: 6.1:1 on white, white on it 6.1:1.
  static const peacock = Color(0xFF0B6E6B);

  /// Loss: errors, destructive actions, a debt. With ink, turmeric and
  /// peacock, the only hues in the app; success, information and a person's
  /// own location are ink, said in words and shapes rather than in green or
  /// blue (0.24 review).
  static const brick = Color(0xFFB8321E);

  /// The pressed state of an ink fill.
  static const slateBlue = Color(0xFF3B4A5A);

  /// What shadows are made from.
  static const shadow = Color(0xFF0B1219);

  /// The shell — the navigation bar and rail — is ink in both themes, and
  /// this is its quiet text and icons: 9.1:1 on ink.
  static const shellMuted = Color(0xFFB8C2CC);

  // --- Dark ----------------------------------------------------------------

  /// Night slate, not black.
  static const night = Color(0xFF0E141A);
  static const nightSurface = Color(0xFF16202A);
  static const nightRaised = Color(0xFF1F2B37);
  static const nightLine = Color(0xFF263241);
  static const nightLineStrong = Color(0xFF6B7A8B);
  static const nightText = Color(0xFFEEF2F5);
  static const nightTextMuted = Color(0xFF9BA7B2);

  /// Turmeric in the dark: the action fill, under ink text (10.2:1), and the
  /// accent as words (8.0:1 on the raised surface).
  static const nightTurmeric = Color(0xFFF5B629);
  static const nightTurmericWash = Color(0xFF33321F);
  static const nightPeacock = Color(0xFF5BBDB7);
  static const nightBrick = Color(0xFFF07A63);

  /// A pin at rest on the dark basemap: 12:1 against the night ground.
  static const nightPin = Color(0xFFC9D2DA);

  /// Your own pins in the dark: warm sand, apart from the turmeric selection.
  static const nightOwnPin = Color(0xFFD9B38C);
}

/// Corner radii (section 31).
class BrandRadius {
  const BrandRadius._();

  static const double small = 8;
  static const double medium = 12; // buttons, inputs
  static const double large = 16; // cards
  static const double sheet = 24; // bottom sheets and dialogs

  static const smallAll = BorderRadius.all(Radius.circular(small));
  static const mediumAll = BorderRadius.all(Radius.circular(medium));
  static const largeAll = BorderRadius.all(Radius.circular(large));
  static const sheetAll = BorderRadius.all(Radius.circular(sheet));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}

/// Touch targets and spacing (section 29).
class BrandSizing {
  const BrandSizing._();

  /// Absolute minimum tappable size.
  static const double touchTargetMinimum = 44;

  /// Preferred tappable size — buttons and controls use this.
  static const double touchTargetPreferred = 48;

  /// A button's height since 0.24: a chunky pill, easy to hit one-handed.
  static const double controlHeight = 52;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  /// Wide-screen gutters. The 4/8/16/24/32 rhythm was drawn for a handset and
  /// is too tight to separate a rail from a canvas.
  static const double spaceXxl = 40;
  static const double space3xl = 56;

  /// The widest a column of text or job rows is allowed to get.
  ///
  /// A job row stretched across a 1440px browser is a 1400px band holding
  /// forty characters, and the eye has to travel the whole way to find the
  /// next line. This is roughly the 60–80 character measure that typography
  /// has settled on, at this app's body size.
  static const double readableWidth = 720;
}

/// Type scale (section 11). Nothing smaller than 12px.
///
/// **Atkinson Hyperlegible Next** since 0.24: drawn for readers with low vision,
/// so I, l and 1 differ, and so do 0 and O. Many people here read slowly, on
/// small screens, outdoors. It carries tabular figures, which fares need.
///
/// **Every style sets its tracking to 0**, the face's own. Section 11 gives
/// sizes and weights and no tracking, so until 0.23 Material's defaults
/// filled the gap when these were merged into the theme: half a pixel on
/// 16px body copy and on 12px captions, which spread the small text out and
/// made "Construction" too wide for its tile.
class BrandType {
  const BrandType._();

  static const String family = 'Atkinson Hyperlegible Next';

  /// Urdu and Arabic-script fallback for mixed-language content.
  static const List<String> fallback = <String>['Noto Sans Arabic'];

  static const display = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    letterSpacing: 0,
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w700,
  );

  static const pageHeading = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    letterSpacing: 0,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
  );

  static const sectionHeading = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    letterSpacing: 0,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    letterSpacing: 0,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  static const supporting = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    letterSpacing: 0,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static const caption = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    letterSpacing: 0,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  /// Button label — body size at semibold, per section 22.
  static const button = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    letterSpacing: 0,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );

  /// A fare. Bold, because it is the first thing a worker scans a list for,
  /// and tabular, so amounts line up down the list instead of jittering with
  /// each digit's width.
  static const fare = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    letterSpacing: 0,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Motion timings (section 28). Motion communicates state, never decorates.
class BrandMotion {
  const BrandMotion._();

  /// Immediate feedback — button presses, marker selection.
  static const fast = Duration(milliseconds: 160);

  /// Standard transitions — sheets, fades, list changes.
  static const standard = Duration(milliseconds: 240);

  /// Large transitions — full-screen route changes.
  static const large = Duration(milliseconds: 340);

  /// **One curve for everything** that moves: a quick start that settles
  /// gently, with no overshoot. There used to be a second, `easeOutBack`,
  /// whose bounce section 28 rules out, and a third written inline.
  /// `design_rules_test.dart` fails on any curve named outside this file.
  static const curve = Cubic(0.22, 1, 0.36, 1);
}
