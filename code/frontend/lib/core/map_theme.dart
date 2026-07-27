import 'package:flutter/material.dart';

import 'tokens.dart';

/// How the map surface is styled in each brightness.
///
/// Section 15 of the brand guidelines asks for a light, low-noise map with
/// readable road labels and unsaturated colour, and section 30 asks for a warm
/// dark mode rather than a cold inverted one. Neither is satisfied by taking a
/// standard OpenStreetMap raster and darkening it — that produces muddy greens
/// and unreadable labels.
///
/// So each brightness gets a purpose-built basemap: CARTO Positron (light) and
/// Dark Matter (dark). Both are deliberately desaturated and label-first, which
/// leaves the burgundy markers as the only saturated thing on the map. A gentle
/// brand tint is laid over the tiles to tie the surface to the palette without
/// touching legibility.
class MapTheme {
  const MapTheme({
    required this.tileUrl,
    required this.backgroundColour,
    required this.tint,
    required this.tintOpacity,
    required this.attribution,
  });

  /// Raster tile template. `{r}` resolves to `@2x` on high-density screens.
  final String tileUrl;

  /// Shown before tiles arrive, and wherever they cannot be fetched — so a
  /// tile-less map still looks deliberate rather than broken.
  final Color backgroundColour;

  /// Brand colour laid over the tiles.
  final Color tint;

  /// Kept low: the tint should be felt, not seen. Anything heavier starts to
  /// hurt label contrast, which section 15 explicitly protects.
  final double tintOpacity;

  final String attribution;

  static const _attribution = '© OpenStreetMap contributors © CARTO';

  /// CARTO Positron — near-white, minimal colour, strong labels.
  static const light = MapTheme(
    tileUrl:
        'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    backgroundColour: BrandColours.warmSand,
    tint: BrandColours.warmSand,
    tintOpacity: 0.30,
    attribution: _attribution,
  );

  /// CARTO Dark Matter — a true dark basemap, warmed towards the brand rather
  /// than left blue-black.
  static const dark = MapTheme(
    tileUrl: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    backgroundColour: BrandColours.darkBackground,
    tint: BrandColours.deepBurgundy,
    tintOpacity: 0.22,
    attribution: _attribution,
  );

  static MapTheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? light : dark;

  /// Marker outline that separates a pin from the basemap underneath it.
  Color get markerOutline =>
      tint == BrandColours.deepBurgundy ? BrandColours.darkTextPrimary : Colors.white;
}
