import 'package:flutter/material.dart';

import 'tokens.dart';

/// Every colour the app draws, named by its job rather than by its hue.
///
/// **Screens use these, never [BrandColours].** Until 0.24 features and
/// widgets named brand colours directly — 123 times in 32 files — so a new
/// palette would have meant editing all of them, and "sand in light, elevated
/// in dark" was written out by hand in eleven places. Now the palette lives in
/// two constants here, [light] and [dark], and a reskin changes those and
/// nothing else. `test/design_rules_test.dart` fails if a screen reaches past
/// this file for a colour.
///
/// The roles, in the playbook's terms: a page, surfaces raised off it, lines,
/// two weights of text, one action colour, and a small set of signals. Each
/// role says where it may be used; a role used for something else is a role
/// that will be wrong after the next reskin.
@immutable
class AppColours extends ThemeExtension<AppColours> {
  const AppColours({
    required this.page,
    required this.surface,
    required this.raised,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.textMuted,
    required this.action,
    required this.onAction,
    required this.actionPressed,
    required this.accentText,
    required this.highlight,
    required this.onHighlight,
    required this.selection,
    required this.tint,
    required this.onTint,
    required this.voice,
    required this.onVoice,
    required this.voiceTrack,
    required this.good,
    required this.bad,
    required this.warn,
    required this.info,
    required this.onSignal,
    required this.fare,
    required this.rating,
    required this.special,
    required this.feature,
    required this.onFeature,
    required this.avatar,
    required this.onAvatar,
    required this.intro,
    required this.inverse,
    required this.onInverse,
    required this.shadow,
    required this.pin,
    required this.pinSelected,
    required this.pinOwn,
    required this.pinOutline,
    required this.pinSelectedOutline,
    required this.pinGlyph,
    required this.pinSelectedGlyph,
    required this.radiusFill,
    required this.radiusBorder,
    required this.user,
    required this.userRing,
  });

  /// The ground every screen sits on.
  final Color page;

  /// Sheets, bars, menus, the map's overlays: things on top of the page.
  final Color surface;

  /// A surface on a surface — the one level above [surface], used sparingly.
  final Color raised;

  /// Hairlines between rows and round cards.
  final Color line;

  /// Input borders and anything a line must be seen against at a glance.
  final Color lineStrong;

  final Color text;
  final Color textMuted;

  /// The one action colour: a screen's primary button, the Post slot.
  final Color action;
  final Color onAction;
  final Color actionPressed;

  /// The action colour as *words*: links, text buttons, the selected tab.
  /// A separate role because a fill colour that reads well under white text
  /// is often too light or too dark to be text itself.
  final Color accentText;

  /// The signature mark: what is selected or new and wants to be seen —
  /// the selected pin, the navigation indicator, "2 offers" waiting.
  final Color highlight;
  final Color onHighlight;

  /// A selected row's fill. Quieter than [highlight]: text sits on it.
  final Color selection;

  /// A quiet filled area: a chip, a tile, the voice note's panel, an avatar.
  final Color tint;
  final Color onTint;

  /// Voice notes, and only voice notes: the play button, the waveform, the
  /// microphone. Voice is the product's first-class way of describing work,
  /// so it keeps a colour nothing else uses.
  final Color voice;
  final Color onVoice;

  /// The part of a waveform not yet played.
  final Color voiceTrack;

  final Color good;
  final Color bad;
  final Color warn;
  final Color info;

  /// Text or a glyph on [good], [bad], [warn] or [info] when they are fills.
  final Color onSignal;

  /// A fare, in figures.
  final Color fare;

  /// Stars.
  final Color rating;

  /// Paid or staff-only things that must not look like an action: a premium
  /// listing, an admin override.
  final Color special;

  /// A panel that carries the brand: the wallet's balance.
  final Color feature;
  final Color onFeature;

  /// An initials avatar for a person with an account.
  final Color avatar;
  final Color onAvatar;

  /// The first-run screens' ground.
  final Color intro;

  /// Things that float over content and must read against anything: the
  /// snack bar, the photo viewer, the map/list switch.
  final Color inverse;
  final Color onInverse;

  /// The colour shadows are made from.
  final Color shadow;

  // --- The map --------------------------------------------------------------

  final Color pin;
  final Color pinSelected;

  /// A pin for a job the person looking posted.
  final Color pinOwn;
  final Color pinOutline;
  final Color pinSelectedOutline;
  final Color pinGlyph;
  final Color pinSelectedGlyph;
  final Color radiusFill;
  final Color radiusBorder;
  final Color user;
  final Color userRing;

  /// The palette in light mode.
  static const light = AppColours(
    page: BrandColours.mist,
    surface: BrandColours.white,
    raised: BrandColours.white,
    line: BrandColours.cardBorder,
    lineStrong: BrandColours.stone,
    text: BrandColours.ink,
    textMuted: BrandColours.slate,
    action: BrandColours.trustBurgundy,
    onAction: BrandColours.white,
    actionPressed: BrandColours.deepBurgundy,
    accentText: BrandColours.trustBurgundy,
    highlight: BrandColours.trustBurgundy,
    onHighlight: BrandColours.white,
    selection: BrandColours.warmSand,
    tint: BrandColours.warmSand,
    onTint: BrandColours.ink,
    voice: BrandColours.copper,
    onVoice: BrandColours.white,
    voiceTrack: BrandColours.stone,
    good: BrandColours.successTeal,
    bad: BrandColours.errorRed,
    warn: BrandColours.warningAmber,
    info: BrandColours.informationBlue,
    onSignal: BrandColours.white,
    fare: BrandColours.deepBurgundy,
    rating: BrandColours.copper,
    special: BrandColours.copper,
    feature: BrandColours.deepBurgundy,
    onFeature: BrandColours.white,
    avatar: BrandColours.copper,
    onAvatar: BrandColours.white,
    intro: BrandColours.warmSand,
    inverse: BrandColours.ink,
    onInverse: BrandColours.white,
    shadow: BrandColours.ink,
    pin: BrandColours.markerDefault,
    pinSelected: BrandColours.markerSelected,
    pinOwn: BrandColours.markerLocal,
    pinOutline: BrandColours.white,
    pinSelectedOutline: BrandColours.markerSelectedOutline,
    pinGlyph: BrandColours.white,
    pinSelectedGlyph: BrandColours.white,
    radiusFill: BrandColours.jobRadiusFill,
    radiusBorder: BrandColours.jobRadiusBorder,
    user: BrandColours.userLocation,
    userRing: BrandColours.userLocationRing,
  );

  /// The palette in dark mode.
  static const dark = AppColours(
    page: BrandColours.darkBackground,
    surface: BrandColours.darkSurface,
    raised: BrandColours.darkElevated,
    line: BrandColours.darkElevated,
    lineStrong: BrandColours.slate,
    text: BrandColours.darkTextPrimary,
    textMuted: BrandColours.darkTextSecondary,
    action: BrandColours.darkBurgundy,
    onAction: BrandColours.white,
    actionPressed: BrandColours.trustBurgundy,
    accentText: BrandColours.darkBurgundyText,
    highlight: BrandColours.darkBurgundy,
    onHighlight: BrandColours.white,
    selection: BrandColours.darkElevated,
    tint: BrandColours.darkElevated,
    onTint: BrandColours.darkTextPrimary,
    voice: BrandColours.darkCopper,
    onVoice: BrandColours.white,
    voiceTrack: BrandColours.slate,
    good: BrandColours.successTeal,
    bad: BrandColours.errorRed,
    warn: BrandColours.warningAmber,
    info: BrandColours.informationBlue,
    onSignal: BrandColours.white,
    fare: BrandColours.darkTextPrimary,
    rating: BrandColours.darkCopper,
    special: BrandColours.darkCopper,
    feature: BrandColours.deepBurgundy,
    onFeature: BrandColours.white,
    avatar: BrandColours.copper,
    onAvatar: BrandColours.white,
    intro: BrandColours.darkBackground,
    inverse: BrandColours.darkElevated,
    onInverse: BrandColours.white,
    shadow: BrandColours.ink,
    pin: BrandColours.markerDefault,
    pinSelected: BrandColours.markerSelected,
    pinOwn: BrandColours.markerLocal,
    pinOutline: BrandColours.white,
    pinSelectedOutline: BrandColours.markerSelectedOutline,
    pinGlyph: BrandColours.white,
    pinSelectedGlyph: BrandColours.white,
    radiusFill: BrandColours.jobRadiusFill,
    radiusBorder: BrandColours.jobRadiusBorder,
    user: BrandColours.userLocation,
    userRing: BrandColours.userLocationRing,
  );

  /// The roles in force here. Falls back by brightness for a widget pumped
  /// under a plain theme in a test.
  static AppColours of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColours>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  List<Color> get _all => [
    page,
    surface,
    raised,
    line,
    lineStrong,
    text,
    textMuted,
    action,
    onAction,
    actionPressed,
    accentText,
    highlight,
    onHighlight,
    selection,
    tint,
    onTint,
    voice,
    onVoice,
    voiceTrack,
    good,
    bad,
    warn,
    info,
    onSignal,
    fare,
    rating,
    special,
    feature,
    onFeature,
    avatar,
    onAvatar,
    intro,
    inverse,
    onInverse,
    shadow,
    pin,
    pinSelected,
    pinOwn,
    pinOutline,
    pinSelectedOutline,
    pinGlyph,
    pinSelectedGlyph,
    radiusFill,
    radiusBorder,
    user,
    userRing,
  ];

  static AppColours _from(List<Color> c) => AppColours(
    page: c[0],
    surface: c[1],
    raised: c[2],
    line: c[3],
    lineStrong: c[4],
    text: c[5],
    textMuted: c[6],
    action: c[7],
    onAction: c[8],
    actionPressed: c[9],
    accentText: c[10],
    highlight: c[11],
    onHighlight: c[12],
    selection: c[13],
    tint: c[14],
    onTint: c[15],
    voice: c[16],
    onVoice: c[17],
    voiceTrack: c[18],
    good: c[19],
    bad: c[20],
    warn: c[21],
    info: c[22],
    onSignal: c[23],
    fare: c[24],
    rating: c[25],
    special: c[26],
    feature: c[27],
    onFeature: c[28],
    avatar: c[29],
    onAvatar: c[30],
    intro: c[31],
    inverse: c[32],
    onInverse: c[33],
    shadow: c[34],
    pin: c[35],
    pinSelected: c[36],
    pinOwn: c[37],
    pinOutline: c[38],
    pinSelectedOutline: c[39],
    pinGlyph: c[40],
    pinSelectedGlyph: c[41],
    radiusFill: c[42],
    radiusBorder: c[43],
    user: c[44],
    userRing: c[45],
  );

  @override
  AppColours copyWith() => this;

  @override
  AppColours lerp(covariant AppColours? other, double t) {
    if (other == null) return this;
    final a = _all;
    final b = other._all;
    return _from([
      for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!,
    ]);
  }
}

/// `context.colours.tint` rather than `AppColours.of(context).tint`.
extension AppColoursContext on BuildContext {
  AppColours get colours => AppColours.of(this);
}
