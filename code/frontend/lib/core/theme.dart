import 'package:flutter/material.dart';

import 'roles.dart';
import 'tokens.dart';

/// Material themes assembled from the role tokens.
///
/// **The Material colour scheme is built from [AppColours]**, so the palette is
/// written down once (in `roles.dart`) and Material's own components — buttons,
/// chips, inputs, tabs, sheets — follow it without being told. Since 0.24 the
/// action colour is ink in light mode and turmeric in dark; controls are pills;
/// cards 16px, sheets 24px.
class BrandTheme {
  const BrandTheme._();

  static ThemeData get light => _base(AppColours.light, Brightness.light);

  static ThemeData get dark => _base(AppColours.dark, Brightness.dark);

  /// The same theme for Urdu: display text in Nastaliq.
  ///
  /// Urdu is read in Nastaliq, and the 0.24 direction names it for display.
  /// The font was bundled and nothing used it, so every heading fell back to
  /// Noto Sans Arabic, a Naskh. Headings, titles, the app bar and dialogs now
  /// prefer Nastaliq for Arabic script; body text stays in Noto Sans Arabic,
  /// which reads better small. Latin letters in the same line (a job title
  /// typed in English) are still Atkinson Hyperlegible Next.
  ///
  /// Nastaliq's letters drop well below the line, so its lines are taller.
  static ThemeData urdu(ThemeData base) {
    TextStyle? nastaliq(TextStyle? style) => style?.copyWith(
      fontFamilyFallback: const ['Noto Nastaliq Urdu', ...BrandType.fallback],
      height: urduDisplayHeight,
    );

    final text = base.textTheme;
    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: nastaliq(text.displayLarge),
        displayMedium: nastaliq(text.displayMedium),
        headlineLarge: nastaliq(text.headlineLarge),
        headlineMedium: nastaliq(text.headlineMedium),
        titleLarge: nastaliq(text.titleLarge),
        titleMedium: nastaliq(text.titleMedium),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: nastaliq(base.appBarTheme.titleTextStyle),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: nastaliq(base.dialogTheme.titleTextStyle),
      ),
    );
  }

  /// Line height for Nastaliq display text: its descenders clip below this.
  static const urduDisplayHeight = 1.9;

  static ColorScheme _scheme(AppColours r, Brightness brightness) =>
      ColorScheme(
        brightness: brightness,
        primary: r.action,
        onPrimary: r.onAction,
        primaryContainer: r.actionPressed,
        onPrimaryContainer: r.onAction,
        secondary: r.voice,
        onSecondary: r.onVoice,
        // Selected segments and tonal buttons sit on this: the quiet
        // turmeric wash, under ink text.
        secondaryContainer: r.selection,
        onSecondaryContainer: r.text,
        tertiary: r.highlight,
        onTertiary: r.onHighlight,
        surface: r.surface,
        onSurface: r.text,
        surfaceContainerLowest: r.surface,
        surfaceContainerLow: r.page,
        surfaceContainer: r.tint,
        surfaceContainerHigh: r.tint,
        surfaceContainerHighest: r.tint,
        onSurfaceVariant: r.textMuted,
        outline: r.lineStrong,
        outlineVariant: r.line,
        error: r.bad,
        onError: r.onSignal,
        inverseSurface: r.inverse,
        onInverseSurface: r.onInverse,
        shadow: r.shadow,
        scrim: r.shadow,
      );

  static ThemeData _base(AppColours roles, Brightness brightness) {
    final scheme = _scheme(roles, brightness);
    final ground = roles.page;
    final isLight = brightness == Brightness.light;
    final textColour = scheme.onSurface;
    final mutedColour = scheme.onSurfaceVariant;
    final accentText = roles.accentText;

    // **Keyboard focus, drawn one way everywhere** (WP11): a 2px ring just
    // outside a focused control, as FocusRing draws round the app's own.
    // Material's default is a wash a few percent darker, which on a text
    // button over the map was close to invisible. Around a filled button the
    // ring is turmeric (near-white in dark), since ink beside ink would only
    // make the button look bigger.
    final ring = BorderSide(
      color: roles.action,
      width: 2,
      strokeAlign: BorderSide.strokeAlignOutside,
    );
    final ringOnFill = ring.copyWith(
      color: isLight ? roles.highlight : roles.text,
    );
    WidgetStateProperty<BorderSide?> focusSide(
      BorderSide focused, [
      BorderSide? rest,
    ]) => WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused) ? focused : rest,
    );

    final textTheme = TextTheme(
      displayLarge: BrandType.display.copyWith(color: textColour),
      displayMedium: BrandType.display.copyWith(color: textColour),
      headlineLarge: BrandType.pageHeading.copyWith(color: textColour),
      headlineMedium: BrandType.pageHeading.copyWith(color: textColour),
      titleLarge: BrandType.sectionHeading.copyWith(color: textColour),
      titleMedium: BrandType.sectionHeading.copyWith(color: textColour),
      bodyLarge: BrandType.body.copyWith(color: textColour),
      bodyMedium: BrandType.supporting.copyWith(color: mutedColour),
      labelLarge: BrandType.button.copyWith(color: textColour),
      labelMedium: BrandType.supporting.copyWith(color: mutedColour),
      labelSmall: BrandType.caption.copyWith(color: mutedColour),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      extensions: <ThemeExtension<dynamic>>[roles],
      fontFamily: BrandType.family,
      fontFamilyFallback: BrandType.fallback,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      // **On the ground, not on white.** A white bar over a mist page over
      // white cards was three surfaces where there is one thing. The bar is
      // now part of the page, and a hairline shadow appears only once content
      // scrolls under it.
      appBarTheme: AppBarTheme(
        backgroundColor: ground,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: roles.shadow.withValues(alpha: isLight ? 0.18 : 0.6),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: BrandType.pageHeading.copyWith(color: scheme.onSurface),
      ),

      // Section 22 — primary button: ink, white text, a 52px pill.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              disabledBackgroundColor: roles.tint,
              disabledForegroundColor: roles.textMuted,
              minimumSize: const Size(0, BrandSizing.controlHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: BrandSizing.spaceLg,
              ),
              elevation: 0,
              textStyle: BrandType.button,
              shape: const StadiumBorder(),
            ).copyWith(
              side: focusSide(ringOnFill),
              // Pressed, the fill darkens a step.
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return roles.tint;
                }
                if (states.contains(WidgetState.pressed)) {
                  return roles.actionPressed;
                }
                return scheme.primary;
              }),
            ),
      ),

      // Section 22 — secondary button: transparent with an ink border.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              // Ink, not turmeric: turmeric is for what is selected or
              // waiting, never a general accent (0.24 review).
              foregroundColor: textColour,
              minimumSize: const Size(0, BrandSizing.controlHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: BrandSizing.spaceLg,
              ),
              textStyle: BrandType.button,
              shape: const StadiumBorder(),
            ).copyWith(
              side: focusSide(
                ring.copyWith(width: 3),
                BorderSide(color: scheme.primary),
              ),
            ),
      ),

      // The same button as the elevated one, for the screens that ask for a
      // filled one: Material's default is a 40px pill, and fourteen of them —
      // "Book this", "Offer a fare", "Send" — sat beside 48px rounded
      // rectangles that were meant to be the same control.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, BrandSizing.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: BrandSizing.spaceLg),
          textStyle: BrandType.button,
          shape: const StadiumBorder(),
        ).copyWith(side: focusSide(ringOnFill)),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textColour,
          minimumSize: const Size(0, BrandSizing.touchTargetMinimum),
          textStyle: BrandType.button,
          shape: const StadiumBorder(),
        ).copyWith(side: focusSide(ring)),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(side: focusSide(ring)),
      ),

      // Section 23 — inputs: white, Stone border, 12px radius, 48px min,
      // 2px ink focus ring, labels always visible above the field.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? roles.surface : roles.raised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BrandSizing.spaceMd,
          vertical: BrandSizing.spaceMd - 2,
        ),
        constraints: const BoxConstraints(
          minHeight: BrandSizing.touchTargetPreferred,
        ),
        hintStyle: BrandType.body.copyWith(color: mutedColour),
        labelStyle: BrandType.supporting.copyWith(color: mutedColour),
        border: OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: roles.lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: roles.bad, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: roles.bad, width: 2),
        ),
      ),

      // Section 24 — cards: white, hairline border, 16px radius, no heavy shadow.
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BrandRadius.largeAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // Section 25 — bottom sheets: 20px top corners.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: roles.lineStrong,
        shape: const RoundedRectangleBorder(borderRadius: BrandRadius.sheetTop),
      ),

      // **The shell is ink, in both themes.** The navigation bar and rail are
      // the one committed field of colour: an ink band with the selected
      // destination on a turmeric pill. It reads in sunlight, and it marks
      // where the app's own controls are, apart from the work above it.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: roles.shell,
        surfaceTintColor: Colors.transparent,
        indicatorColor: roles.highlight,
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return BrandType.caption.copyWith(
            color: selected ? roles.onShell : roles.shellMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? roles.onHighlight : roles.shellMuted,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: roles.shell,
        indicatorColor: roles.highlight,
        selectedIconTheme: IconThemeData(color: roles.onHighlight, size: 24),
        unselectedIconTheme: IconThemeData(color: roles.shellMuted, size: 24),
        selectedLabelTextStyle: BrandType.supporting.copyWith(
          color: roles.onShell,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: BrandType.supporting.copyWith(
          color: roles.shellMuted,
          fontWeight: FontWeight.w500,
        ),
      ),

      // A row in a settings group: the title carries a little more weight than
      // body copy, so a list of them reads as a list of places to go.
      listTileTheme: ListTileThemeData(
        iconColor: mutedColour,
        titleTextStyle: BrandType.body.copyWith(
          color: textColour,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: BrandType.supporting.copyWith(color: mutedColour),
      ),

      // Section 22 — a control is 48px tall with a 12px radius, segmented ones
      // included; Material's default is a 40px pill.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, BrandSizing.touchTargetPreferred),
          ),
          textStyle: WidgetStatePropertyAll(
            BrandType.supporting.copyWith(fontWeight: FontWeight.w600),
          ),
          side: focusSide(
            ring.copyWith(strokeAlign: BorderSide.strokeAlignInside),
            BorderSide(color: scheme.outline),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 1,
        extendedTextStyle: BrandType.button,
        shape: const StadiumBorder(),
      ),

      // Section 25 — a dialogue is a sheet that sits in the middle, so it has
      // the sheet's corners.
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BrandRadius.sheetAll),
        titleTextStyle: BrandType.sectionHeading.copyWith(color: textColour),
        contentTextStyle: BrandType.body.copyWith(color: mutedColour),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: roles.surface,
        selectedColor: roles.selection,
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? ring.copyWith(strokeAlign: BorderSide.strokeAlignInside)
              : BorderSide(color: scheme.outlineVariant),
        ),
        labelStyle: BrandType.supporting.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSizing.spaceSm + 4,
          vertical: BrandSizing.spaceSm,
        ),
        shape: const StadiumBorder(),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: accentText,
        unselectedLabelColor: mutedColour,
        labelStyle: BrandType.supporting.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: BrandType.supporting.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: accentText,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outlineVariant,
        overlayColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: 0.06),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: roles.shadow.withValues(alpha: 0.25),
        shape: const RoundedRectangleBorder(
          borderRadius: BrandRadius.mediumAll,
        ),
        textStyle: BrandType.body.copyWith(color: textColour),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: roles.inverse,
        contentTextStyle: BrandType.supporting.copyWith(color: roles.onInverse),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BrandRadius.mediumAll,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: scheme.outlineVariant,
      ),

      // Section 28 — transitions communicate the change and get out of the
      // way. A fade-forward on both platforms, no bounce or parallax.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Brand styles that Material's text theme has no slot for.
extension BrandTextStyles on ThemeData {
  AppColours get _roles =>
      extension<AppColours>() ??
      (brightness == Brightness.dark ? AppColours.dark : AppColours.light);

  /// The accent as words. Prefer `context.colours.accentText`; this is for
  /// code that holds a [ThemeData] and no context.
  Color get accentText => _roles.accentText;

  /// A fare, in figures that line up down a list, in the fare role's colour.
  TextStyle get fareStyle => BrandType.fare.copyWith(color: _roles.fare);
}
