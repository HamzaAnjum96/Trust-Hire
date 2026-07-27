import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material themes assembled from the brand tokens.
///
/// Component styling follows sections 22–25 of the brand guidelines: 48px
/// minimum control height, 12px control radius, 16px card radius, 20px sheet
/// corners, subtle shadows, and burgundy reserved for primary actions.
class BrandTheme {
  const BrandTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: BrandColours.trustBurgundy,
      onPrimary: BrandColours.white,
      primaryContainer: BrandColours.deepBurgundy,
      onPrimaryContainer: BrandColours.white,
      secondary: BrandColours.copper,
      onSecondary: BrandColours.white,
      secondaryContainer: BrandColours.warmSand,
      onSecondaryContainer: BrandColours.ink,
      surface: BrandColours.white,
      onSurface: BrandColours.ink,
      surfaceContainerLowest: BrandColours.white,
      surfaceContainerLow: BrandColours.mist,
      surfaceContainer: BrandColours.warmSand,
      onSurfaceVariant: BrandColours.slate,
      outline: BrandColours.stone,
      outlineVariant: BrandColours.cardBorder,
      error: BrandColours.errorRed,
      onError: BrandColours.white,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: BrandColours.mist,
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: BrandColours.darkBurgundy,
      onPrimary: BrandColours.white,
      primaryContainer: BrandColours.trustBurgundy,
      onPrimaryContainer: BrandColours.darkTextPrimary,
      secondary: BrandColours.darkCopper,
      onSecondary: BrandColours.ink,
      secondaryContainer: BrandColours.darkElevated,
      onSecondaryContainer: BrandColours.darkTextPrimary,
      surface: BrandColours.darkSurface,
      onSurface: BrandColours.darkTextPrimary,
      surfaceContainerLowest: BrandColours.darkBackground,
      surfaceContainerLow: BrandColours.darkSurface,
      surfaceContainer: BrandColours.darkElevated,
      onSurfaceVariant: BrandColours.darkTextSecondary,
      outline: BrandColours.slate,
      outlineVariant: BrandColours.darkElevated,
      error: BrandColours.errorRed,
      onError: BrandColours.white,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: BrandColours.darkBackground,
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final textColour = scheme.onSurface;
    final mutedColour = scheme.onSurfaceVariant;

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
      fontFamily: BrandType.family,
      fontFamilyFallback: BrandType.fallback,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: BrandType.pageHeading.copyWith(color: scheme.onSurface),
      ),

      // Section 22 — primary button: burgundy, white text, 48px, 12px radius.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: BrandColours.stone,
          disabledForegroundColor: BrandColours.white,
          minimumSize: const Size(0, BrandSizing.touchTargetPreferred),
          padding: const EdgeInsets.symmetric(horizontal: BrandSizing.spaceLg),
          elevation: 0,
          textStyle: BrandType.button,
          shape: const RoundedRectangleBorder(
            borderRadius: BrandRadius.mediumAll,
          ),
        ).copyWith(
          // Pressed state darkens to Deep Burgundy in light mode.
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BrandColours.stone;
            }
            if (states.contains(WidgetState.pressed)) {
              return isLight
                  ? BrandColours.deepBurgundy
                  : BrandColours.trustBurgundy;
            }
            return scheme.primary;
          }),
        ),
      ),

      // Section 22 — secondary button: transparent with a burgundy border.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, BrandSizing.touchTargetPreferred),
          padding: const EdgeInsets.symmetric(horizontal: BrandSizing.spaceLg),
          side: BorderSide(color: scheme.primary),
          textStyle: BrandType.button,
          shape: const RoundedRectangleBorder(
            borderRadius: BrandRadius.mediumAll,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, BrandSizing.touchTargetMinimum),
          textStyle: BrandType.button,
          shape: const RoundedRectangleBorder(
            borderRadius: BrandRadius.mediumAll,
          ),
        ),
      ),

      // Section 23 — inputs: white, Stone border, 12px radius, 48px min,
      // 2px burgundy focus ring, labels always visible above the field.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? BrandColours.white : BrandColours.darkElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BrandSizing.spaceMd,
          vertical: BrandSizing.spaceMd - 2,
        ),
        constraints: const BoxConstraints(
          minHeight: BrandSizing.touchTargetPreferred,
        ),
        hintStyle: BrandType.body.copyWith(color: mutedColour),
        labelStyle: BrandType.supporting.copyWith(color: mutedColour),
        border: const OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: BrandColours.stone),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: BrandColours.errorRed, width: 2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BrandRadius.mediumAll,
          borderSide: BorderSide(color: BrandColours.errorRed, width: 2),
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
        dragHandleColor: BrandColours.stone,
        shape: const RoundedRectangleBorder(
          borderRadius: BrandRadius.sheetTop,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isLight
            ? BrandColours.warmSand
            : BrandColours.darkElevated,
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return BrandType.caption.copyWith(
            color: selected ? scheme.primary : mutedColour,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : mutedColour,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isLight ? BrandColours.white : BrandColours.darkElevated,
        selectedColor: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: BrandType.supporting.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSizing.spaceSm + 4,
          vertical: BrandSizing.spaceSm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BrandRadius.mediumAll,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? BrandColours.ink : BrandColours.darkElevated,
        contentTextStyle: BrandType.supporting.copyWith(
          color: BrandColours.white,
        ),
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
