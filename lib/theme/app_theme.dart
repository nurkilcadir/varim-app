import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:varim_app/theme/design_system.dart';

/// Custom color scheme extension for VARIM app
@immutable
class VarimColors extends ThemeExtension<VarimColors> {
  final Color varimColor;
  final Color yokumColor;
  final Color cardBackground;
  final Color headerAccent;
  final Color headerAccentDark;
  final Color categoryGlowTrend;
  final Color categoryGlowEconomy;

  const VarimColors({
    required this.varimColor,
    required this.yokumColor,
    required this.cardBackground,
    required this.headerAccent,
    required this.headerAccentDark,
    required this.categoryGlowTrend,
    required this.categoryGlowEconomy,
  });

  @override
  VarimColors copyWith({
    Color? varimColor,
    Color? yokumColor,
    Color? cardBackground,
    Color? headerAccent,
    Color? headerAccentDark,
    Color? categoryGlowTrend,
    Color? categoryGlowEconomy,
  }) {
    return VarimColors(
      varimColor: varimColor ?? this.varimColor,
      yokumColor: yokumColor ?? this.yokumColor,
      cardBackground: cardBackground ?? this.cardBackground,
      headerAccent: headerAccent ?? this.headerAccent,
      headerAccentDark: headerAccentDark ?? this.headerAccentDark,
      categoryGlowTrend: categoryGlowTrend ?? this.categoryGlowTrend,
      categoryGlowEconomy: categoryGlowEconomy ?? this.categoryGlowEconomy,
    );
  }

  @override
  VarimColors lerp(ThemeExtension<VarimColors>? other, double t) {
    if (other is! VarimColors) {
      return this;
    }
    return VarimColors(
      varimColor: Color.lerp(varimColor, other.varimColor, t)!,
      yokumColor: Color.lerp(yokumColor, other.yokumColor, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      headerAccent: Color.lerp(headerAccent, other.headerAccent, t)!,
      headerAccentDark: Color.lerp(headerAccentDark, other.headerAccentDark, t)!,
      categoryGlowTrend: Color.lerp(categoryGlowTrend, other.categoryGlowTrend, t)!,
      categoryGlowEconomy: Color.lerp(categoryGlowEconomy, other.categoryGlowEconomy, t)!,
    );
  }
}

/// VARIM App Theme
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: DesignSystem.successGreen,
        secondary: DesignSystem.errorRose,
        surface: DesignSystem.backgroundDeep,
        surfaceContainerHighest: DesignSystem.border,
        surfaceContainer: DesignSystem.surfaceLight,
        surfaceContainerLow: DesignSystem.backgroundDeep,
        tertiary: DesignSystem.primaryAccent,
        error: DesignSystem.errorRose,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: DesignSystem.textHeading,
        onSurfaceVariant: DesignSystem.textBody,
        onError: Colors.white,
      ),
      
      extensions: <ThemeExtension<dynamic>>[
        const VarimColors(
          varimColor: DesignSystem.successGreen,
          yokumColor: DesignSystem.errorRose,
          cardBackground: DesignSystem.surfaceLight,
          headerAccent: DesignSystem.primaryAccent,
          headerAccentDark: Color(0xFF2563EB),
          categoryGlowTrend: Color(0xFFF59E0B),
          categoryGlowEconomy: Color(0xFFFBBF24),
        ),
      ],
      
      scaffoldBackgroundColor: DesignSystem.backgroundDeep,
      cardColor: DesignSystem.surfaceLight,
      
      cardTheme: CardThemeData(
        color: DesignSystem.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1), // Subtle white border for crisp separation
            width: 1,
          ),
        ),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000), // Pure Black - blends with background
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white, // Pure white for high contrast
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DesignSystem.surfaceLight,
        selectedItemColor: DesignSystem.primaryAccent,
        unselectedItemColor: DesignSystem.unselectedItem,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
      ),
      
      dividerColor: Colors.white.withValues(alpha: 0.1), // Subtle white divider
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
      ),
      
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: DesignSystem.textHeading),
          displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: DesignSystem.textHeading),
          displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: DesignSystem.textHeading),
          headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: DesignSystem.textHeading),
          headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: DesignSystem.textHeading),
          titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: DesignSystem.textHeading),
          titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: DesignSystem.textBody),
          bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: DesignSystem.textBody),
          bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: DesignSystem.textBody),
          bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: DesignSystem.textBody),
          labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: DesignSystem.textHeading),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.primaryAccent,
          foregroundColor: DesignSystem.textHeading,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignSystem.primaryAccent,
          side: const BorderSide(color: DesignSystem.primaryAccent, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignSystem.primaryAccent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignSystem.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1), // Subtle white border
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DesignSystem.primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DesignSystem.errorRose, width: 1),
        ),
        labelStyle: GoogleFonts.inter(color: DesignSystem.textBody, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: DesignSystem.textBody, fontSize: 14),
      ),
      
      iconTheme: const IconThemeData(color: Colors.white70, size: 24), // White70 for icons
    );
  }
  
  static VarimColors varimColors(BuildContext context) {
    return Theme.of(context).extension<VarimColors>() ?? 
           const VarimColors(
             varimColor: DesignSystem.successGreen,
             yokumColor: DesignSystem.errorRose,
             cardBackground: DesignSystem.surfaceLight,
             headerAccent: DesignSystem.primaryAccent,
             headerAccentDark: Color(0xFF2563EB),
             categoryGlowTrend: Color(0xFFF59E0B),
             categoryGlowEconomy: Color(0xFFFBBF24),
           );
  }
}
