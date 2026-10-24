import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'tokens.dart';

/// How the map surface is styled in each brightness.
///
/// Section 15 of the brand guidelines asks for a light, low-noise map with
/// readable road labels and unsaturated colour, and section 30 asks for a warm
/// dark mode rather than a cold inverted one. Neither is satisfied by taking a
/// standard OpenStreetMap raster and darkening it — that produces muddy greens
/// and unreadable labels.
///
/// So each brightness gets a purpose-built basemap: Esri's Light Gray and Dark
/// Gray Canvas. Both are deliberately desaturated, which leaves the burgundy
/// markers as the only saturated thing on the map. A gentle brand tint is laid
/// over the tiles to tie the surface to the palette, and the place names sit
/// on a layer of their own *above* that tint, so it never touches legibility.
///
/// **Why not CARTO any more.** Positron and Dark Matter were the basemaps here
/// until CARTO started answering keyless requests with a tile that reads
/// "API KEY REQUIRED" — a 200 with a valid PNG, so nothing errored and the
/// fallback never fired: every map in the app quietly showed the same grey
/// placard. Esri's canvas needs no key and sends CORS headers, which the web
/// build cannot do without.
///
/// **A keyed provider for production.** Pass `--dart-define=MAP_TILES_LIGHT=`
/// and `MAP_TILES_DARK=` with a full template — key included — and, if its
/// licence asks for different wording, `MAP_TILES_ATTRIBUTION=`. A provider
/// passed this way is assumed to draw its own labels.
class MapTheme {
  const MapTheme({
    required this.tileUrl,
    required this.backgroundColour,
    required this.tint,
    required this.tintOpacity,
    required this.attribution,
    this.labelUrl,
    this.maxNativeZoom = 19,
  });

  /// Raster tile template for the basemap.
  final String tileUrl;

  /// Place and road names, drawn over the tint. Null when the basemap carries
  /// its own.
  final String? labelUrl;

  /// The deepest zoom the provider actually has tiles for. Past it, the map
  /// scales the last real tile rather than asking for one that is not there —
  /// Esri's canvas answers z17 with a grey "Map data not yet available".
  final int maxNativeZoom;

  /// Shown before tiles arrive, and wherever they cannot be fetched — so a
  /// tile-less map still looks deliberate rather than broken.
  final Color backgroundColour;

  /// Brand colour laid over the tiles.
  final Color tint;

  /// Kept low: the tint should be felt, not seen. Anything heavier starts to
  /// hurt label contrast, which section 15 explicitly protects.
  final double tintOpacity;

  final String attribution;

  static const _lightOverride = String.fromEnvironment('MAP_TILES_LIGHT');
  static const _darkOverride = String.fromEnvironment('MAP_TILES_DARK');
  static const _attributionOverride = String.fromEnvironment(
    'MAP_TILES_ATTRIBUTION',
  );

  static const _esri =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas';

  static const _esriAttribution =
      'Esri, HERE, Garmin, © OpenStreetMap contributors';

  /// Esri Light Gray Canvas — near-white, minimal colour, quiet labels.
  static const light = MapTheme(
    tileUrl: _lightOverride != ''
        ? _lightOverride
        : '$_esri/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    labelUrl: _lightOverride != ''
        ? null
        : '$_esri/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
    maxNativeZoom: _lightOverride != '' ? 19 : 16,
    backgroundColour: BrandColours.warmSand,
    tint: BrandColours.warmSand,
    tintOpacity: 0.30,
    attribution: _attributionOverride != ''
        ? _attributionOverride
        : _esriAttribution,
  );

  /// Esri Dark Gray Canvas — a true dark basemap, warmed towards the brand
  /// rather than left blue-black.
  static const dark = MapTheme(
    tileUrl: _darkOverride != ''
        ? _darkOverride
        : '$_esri/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    labelUrl: _darkOverride != ''
        ? null
        : '$_esri/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
    maxNativeZoom: _darkOverride != '' ? 19 : 16,
    backgroundColour: BrandColours.darkBackground,
    tint: BrandColours.deepBurgundy,
    tintOpacity: 0.22,
    attribution: _attributionOverride != ''
        ? _attributionOverride
        : _esriAttribution,
  );

  static MapTheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? light : dark;

  /// The tile layer for this theme.
  ///
  /// Built here rather than at each call site so the three maps in the app —
  /// the main one, the details preview and the area picker — cannot drift
  /// apart. Disk caching is off: the POC does not need it, and it pulls in
  /// path_provider, which then throws on any platform without it.
  TileLayer tileLayer(
    BuildContext context, {
    TileProvider? provider,
    VoidCallback? onTileError,
  }) => _layer(tileUrl, provider: provider, onTileError: onTileError);

  /// The place names, for maps that have [labelUrl]. Goes above [tintLayer].
  ///
  /// Never reports an error: a missing label tile leaves the basemap readable,
  /// and the basemap already says when the network is gone.
  Widget labelLayer(BuildContext context, {TileProvider? provider}) {
    final url = labelUrl;
    if (url == null) return const SizedBox.shrink();
    return IgnorePointer(child: _layer(url, provider: provider));
  }

  TileLayer _layer(
    String url, {
    TileProvider? provider,
    VoidCallback? onTileError,
  }) {
    return TileLayer(
      urlTemplate: url,
      userAgentPackageName: 'com.trusthire.trust_hire',
      maxNativeZoom: maxNativeZoom,
      tileProvider:
          provider ??
          NetworkTileProvider(
            cachingProvider: const DisabledMapCachingProvider(),
          ),
      errorTileCallback: onTileError == null
          ? null
          : (_, _, _) => onTileError(),
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
    );
  }

  /// The brand tint laid over the basemap. Sits under everything else so
  /// markers and work areas stay untinted.
  Widget tintLayer() => IgnorePointer(
    child: ColoredBox(
      color: tint.withValues(alpha: tintOpacity),
      child: const SizedBox.expand(),
    ),
  );

  /// Marker outline that separates a pin from the basemap underneath it.
  Color get markerOutline => tint == BrandColours.deepBurgundy
      ? BrandColours.darkTextPrimary
      : Colors.white;
}
