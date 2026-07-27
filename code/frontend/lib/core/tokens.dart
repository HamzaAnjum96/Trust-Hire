import 'package:flutter/material.dart';

/// Design tokens from `documents/brand-guidelines/brand-guidelines.md`.
///
/// This file is the Dart equivalent of the CSS custom properties in section 31
/// of the guidelines. It is the single source of truth for colour, radius,
/// spacing, type and motion in the app — screens should reference these rather
/// than hard-coding values, so a brand change lands in one place.
class BrandColours {
  const BrandColours._();

  // --- Primary palette (section 5) ---

  /// The main brand colour. Prominent, but not on every surface.
  static const trustBurgundy = Color(0xFF7A263A);

  /// High-contrast states and darker brand surfaces.
  static const deepBurgundy = Color(0xFF4A1524);

  /// Secondary accent — voice notes, new-job badges, radius controls.
  /// Contrast on white is 3.82:1, so it is large-text-only for type.
  static const copper = Color(0xFFC56A3A);

  /// Soft background that keeps the product from feeling clinical.
  static const warmSand = Color(0xFFF4E9DE);

  // --- Neutrals (section 6) ---

  static const ink = Color(0xFF211B1D);
  static const slate = Color(0xFF625A5D);
  static const stone = Color(0xFFB9AFB1);
  static const mist = Color(0xFFF7F4F3);
  static const white = Color(0xFFFFFFFF);

  /// Card border from section 24.
  static const cardBorder = Color(0xFFE7DFE1);

  // --- Functional (section 7) ---
  // Deliberately distinct from the brand palette. Success is a muted
  // blue-teal rather than green, per the guidelines.

  static const successTeal = Color(0xFF287C7A);
  static const informationBlue = Color(0xFF356A8A);

  /// Contrast on white is 2.65:1 — never use as text on a light surface.
  /// Use as a fill with Ink on top, or as an icon at large sizes.
  static const warningAmber = Color(0xFFD3922E);
  static const errorRed = Color(0xFFB63A3A);

  // --- Dark mode (section 30) ---
  // Warm rather than pure black, and no neon.

  static const darkBackground = Color(0xFF181315);
  static const darkSurface = Color(0xFF241C1F);
  static const darkElevated = Color(0xFF302429);
  static const darkTextPrimary = Color(0xFFFAF6F4);
  static const darkTextSecondary = Color(0xFFC7BFC1);

  /// Lighter burgundy for visibility on dark surfaces. 3.64:1 on the dark
  /// background — large text and UI elements, not body copy.
  static const darkBurgundy = Color(0xFFB44C65);
  static const darkCopper = Color(0xFFDB8453);

  // --- Map surface (section 15) ---

  static const markerDefault = trustBurgundy;
  static const markerSelected = deepBurgundy;
  static const markerSelectedOutline = copper;

  /// Locally created jobs are marked in copper so they stand out from seeded
  /// ones — the POC stores them on device only.
  static const markerLocal = copper;

  static const jobRadiusFill = Color(0x1F7A263A); // rgba(122, 38, 58, 0.12)
  static const jobRadiusBorder = Color(0x8C7A263A); // rgba(122, 38, 58, 0.55)

  /// User location uses Information Blue, not green.
  static const userLocation = informationBlue;
  static const userLocationRing = Color(0x33356A8A); // rgba(53, 106, 138, 0.20)
}

/// Corner radii (section 31).
class BrandRadius {
  const BrandRadius._();

  static const double small = 8;
  static const double medium = 12; // buttons, inputs
  static const double large = 16; // cards
  static const double sheet = 20; // bottom sheets

  static const smallAll = BorderRadius.all(Radius.circular(small));
  static const mediumAll = BorderRadius.all(Radius.circular(medium));
  static const largeAll = BorderRadius.all(Radius.circular(large));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}

/// Touch targets and spacing (section 29).
class BrandSizing {
  const BrandSizing._();

  /// Absolute minimum tappable size.
  static const double touchTargetMinimum = 44;

  /// Preferred tappable size — buttons and controls use this.
  static const double touchTargetPreferred = 48;

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

/// Elevation (section 24) — subtle, never heavy, no glow.
class BrandShadows {
  const BrandShadows._();

  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x14211B1D), // rgba(33, 27, 29, 0.08)
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const sheet = <BoxShadow>[
    BoxShadow(color: Color(0x1F211B1D), blurRadius: 24, offset: Offset(0, -4)),
  ];
}

/// Type scale (section 11). Nothing smaller than 12px.
class BrandType {
  const BrandType._();

  static const String family = 'Inter';

  /// Urdu and Arabic-script fallback for mixed-language content.
  static const List<String> fallback = <String>['Noto Sans Arabic'];

  static const display = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w700,
  );

  static const pageHeading = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
  );

  static const sectionHeading = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  static const supporting = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static const caption = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  /// Button label — body size at semibold, per section 22.
  static const button = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
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

  static const curve = Curves.easeOutCubic;
  static const emphasisCurve = Curves.easeOutBack;
}
