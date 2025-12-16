import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom color scheme extension for VARIM app
@immutable
class VarimColors extends ThemeExtension<VarimColors> {
  final Color varimColor; // Neon Electric Green (YES)
  final Color yokumColor; // Neon Hot Pink (NO)
  final Color cardBackground; // Card background color
  final Color headerAccent; // Blue accent for header/VP badge
  final Color headerAccentDark; // Darker blue for gradients
  final Color categoryGlowTrend; // Orange for Trend category
  final Color categoryGlowEconomy; // Gold for Economy category

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

/// VARIM App Theme Configuration
/// Modern Dark Mode with Neon Accent Colors
class AppTheme {
  /// Main theme data for the app (Dark Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme - All colors defined here
      colorScheme: const ColorScheme.dark(
        // Primary colors
        primary: Color(0xFF00FF94), // Neon Electric Green (VARIM/YES)
        secondary: Color(0xFFFF0055), // Neon Hot Pink (YOKUM/NO)
        
        // Surface colors
        surface: Color(0xFF121212), // Deep charcoal background (main surface)
        surfaceContainerHighest: Color(0xFF2C2C2C), // Surface variant
        surfaceContainer: Color(0xFF181818), // Card background
        surfaceContainerLow: Color(0xFF1E1E1E), // Surface dark
        
        // Error
        error: Color(0xFFCF6679),
        
        // On colors (text/icons on colored backgrounds)
        onPrimary: Color(0xFF000000), // Black text on neon green
        onSecondary: Color(0xFFFFFFFF), // White text on neon pink
        onSurface: Color(0xFFFFFFFF), // Text on surface
        onSurfaceVariant: Color(0xFFB0B0B0), // Muted text
        onError: Color(0xFF000000),
      ),
      
      // Custom color extensions
      extensions: <ThemeExtension<dynamic>>[
        const VarimColors(
          varimColor: Color(0xFF00FF94), // Neon Electric Green
          yokumColor: Color(0xFFFF0055), // Neon Hot Pink
          cardBackground: Color(0xFF181818), // Darker card background
          headerAccent: Color(0xFF4A9EFF), // Blue accent
          headerAccentDark: Color(0xFF0066CC), // Darker blue
          categoryGlowTrend: Color(0xFFFF6B35), // Orange
          categoryGlowEconomy: Color(0xFFFFD700), // Gold
        ),
      ],
      
      // Scaffold Background
      scaffoldBackgroundColor: const Color(0xFF121212), // Same as surface
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFFFFFFF),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Text Theme
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFFFFF),
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFFFFF),
          ),
          displaySmall: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF),
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF),
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF),
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF),
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFE0E0E0),
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: const Color(0xFFE0E0E0),
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: const Color(0xFFE0E0E0),
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: const Color(0xFFB0B0B0),
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF94),
          foregroundColor: const Color(0xFF000000),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00FF94),
          side: const BorderSide(color: Color(0xFF00FF94), width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF00FF94),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00FF94), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFFB0B0B0),
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFFB0B0B0),
          fontSize: 14,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFFE0E0E0),
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C),
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  /// Helper extension to access custom colors from theme
  static VarimColors varimColors(BuildContext context) {
    return Theme.of(context).extension<VarimColors>() ?? 
           const VarimColors(
             varimColor: Color(0xFF00FF94),
             yokumColor: Color(0xFFFF0055),
             cardBackground: Color(0xFF181818),
             headerAccent: Color(0xFF4A9EFF),
             headerAccentDark: Color(0xFF0066CC),
             categoryGlowTrend: Color(0xFFFF6B35),
             categoryGlowEconomy: Color(0xFFFFD700),
           );
  }
}
