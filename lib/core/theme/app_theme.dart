import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF080808);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color fallbackAccent = Color(0xFF6C63FF);

  // Semantic aliases used by feature widgets directly.
  static const Color onDark = Color(0xFFF0F0F0);
  static const Color onDarkSecondary = Color(0xFF9E9E9E);

  // Getters rather than consts so they can be overridden via InheritedWidget
  // in a future per-profile theming pass without a breaking API change.
  static double get radiusStandard => 16;
  static double get radiusCard => 24;
  static double get radiusArt => 32;

  static ThemeData dark(Color accentColor) {
    final cs = const ColorScheme.dark().copyWith(
      primary: accentColor,
      onPrimary: contrastColor(accentColor),
      primaryContainer: accentColor.withValues(alpha: 0.15),
      onPrimaryContainer: accentColor,
      secondary: accentColor.withValues(alpha: 0.6),
      onSecondary: contrastColor(accentColor),
      secondaryContainer: accentColor.withValues(alpha: 0.1),
      onSecondaryContainer: onDark,
      surface: surface,
      onSurface: onDark,
      surfaceContainerLowest: background,
      surfaceContainerLow: const Color(0xFF0E0E0E),
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainerHighest: surfaceElevated,
      surfaceDim: background,
      surfaceBright: const Color(0xFF2A2A2A),
      onSurfaceVariant: onDarkSecondary,
      outline: Colors.white.withValues(alpha: 0.12),
      outlineVariant: Colors.white.withValues(alpha: 0.06),
      shadow: Colors.black,
      scrim: Colors.black.withValues(alpha: 0.6),
      inverseSurface: Colors.white,
      onInverseSurface: background,
      inversePrimary: accentColor.withValues(alpha: 0.8),
      error: const Color(0xFFCF6679),
      onError: Colors.white,
      errorContainer: const Color(0xFF3B1420),
      onErrorContainer: const Color(0xFFFF8FA3),
    );

    final tt = _textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: Colors.white.withValues(alpha: 0.08),
      textTheme: tt,
      primaryTextTheme: tt,
      iconTheme: const IconThemeData(color: onDark, size: 24),
      primaryIconTheme: IconThemeData(color: accentColor, size: 24),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: onDark, size: 24),
        actionsIconTheme: const IconThemeData(color: onDarkSecondary, size: 24),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: onDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        margin: EdgeInsets.zero,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentColor.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? IconThemeData(color: accentColor, size: 24)
              : const IconThemeData(color: onDarkSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? GoogleFonts.plusJakartaSans(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )
              : GoogleFonts.plusJakartaSans(
                  color: onDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        // White thumb keeps the slider readable regardless of accent hue.
        thumbColor: Colors.white,
        overlayColor: accentColor.withValues(alpha: 0.12),
        secondaryActiveTrackColor: accentColor.withValues(alpha: 0.3),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6,
          pressedElevation: 0,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const RoundedRectSliderTrackShape(),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.never,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: onDarkSecondary, fontSize: 15),
        labelStyle: GoogleFonts.plusJakartaSans(color: onDarkSecondary, fontSize: 15),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: accentColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: onDarkSecondary,
        suffixIconColor: onDarkSecondary,
        errorStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFFCF6679),
          fontSize: 12,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: contrastColor(accentColor),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
          disabledForegroundColor: onDarkSecondary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusStandard),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          disabledForegroundColor: onDarkSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusStandard),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          disabledForegroundColor: onDarkSecondary,
          side: BorderSide(color: accentColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusStandard),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : onDarkSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? accentColor
              : Colors.white.withValues(alpha: 0.12);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? accentColor
              : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(contrastColor(accentColor)),
        side: const BorderSide(color: onDarkSecondary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        splashRadius: 16,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: accentColor.withValues(alpha: 0.15),
        disabledColor: Colors.white.withValues(alpha: 0.06),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onDark,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        iconTheme: const IconThemeData(color: onDarkSecondary, size: 18),
        deleteIconColor: onDarkSecondary,
        brightness: Brightness.dark,
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: accentColor.withValues(alpha: 0.08),
        iconColor: onDarkSecondary,
        textColor: onDark,
        selectedColor: accentColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surfaceElevated,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onDark,
        ),
        iconColor: onDarkSecondary,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: Color(0x3DFFFFFF),
        dragHandleSize: Size(36, 4),
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onDark,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onDarkSecondary,
        ),
        alignment: Alignment.center,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onDark,
        ),
        actionTextColor: accentColor,
        disabledActionTextColor: onDarkSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        showCloseIcon: false,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: Colors.white.withValues(alpha: 0.12),
        linearMinHeight: 3,
        circularTrackColor: Colors.white.withValues(alpha: 0.12),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(accentColor.withValues(alpha: 0.5)),
        trackColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.dragged) ? 6.0 : 4.0),
        interactive: true,
        thumbVisibility: WidgetStateProperty.all(true),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: onDark,
        ),
        waitDuration: const Duration(milliseconds: 500),
        preferBelow: false,
      ),

      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme get _textTheme {
    final base = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: onDark, fontWeight: FontWeight.w700),
      displayMedium: base.displayMedium?.copyWith(color: onDark, fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(color: onDark, fontWeight: FontWeight.w700),
      headlineLarge: base.headlineLarge?.copyWith(color: onDark, fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(color: onDark, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(color: onDark, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(color: onDark, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: onDark, fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(color: onDark, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(color: onDark),
      bodyMedium: base.bodyMedium?.copyWith(color: onDarkSecondary),
      bodySmall: base.bodySmall?.copyWith(color: onDarkSecondary),
      labelLarge: base.labelLarge?.copyWith(color: onDark, fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(color: onDarkSecondary, fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(color: onDarkSecondary, fontWeight: FontWeight.w500),
    );
  }

  // WCAG-derived threshold: colours below ~0.35 luminance read better with
  // white text; above that point the surface is light enough for dark ink.
  static Color contrastColor(Color bg) {
    return bg.computeLuminance() > 0.35 ? const Color(0xFF0D0D0D) : Colors.white;
  }
}
