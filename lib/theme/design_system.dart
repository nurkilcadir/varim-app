import 'package:flutter/material.dart';

/// Modern Slate & Neon Design System
/// Source of Truth for all colors and styling across the app
class DesignSystem {
  // Core Colors
  static const Color backgroundDeep = Color(0xFF0F172A); // Deep Slate
  static const Color surfaceLight = Color(0xFF1E293B); // Lighter Slate
  static const Color primaryAccent = Color(0xFF3B82F6); // Electric Blue
  static const Color successGreen = Color(0xFF10B981); // Neon Emerald
  static const Color errorRose = Color(0xFFF43F5E); // Neon Rose
  static const Color textHeading = Color(0xFFF8FAFC); // Off-White
  static const Color textBody = Color(0xFF94A3B8); // Slate Grey
  static const Color border = Color(0xFF334155); // Subtle Slate
  static const Color unselectedItem = Color(0xFF64748B); // Nav unselected

  // Semantic Colors
  static const Color profit = successGreen;
  static const Color loss = errorRose;
  static const Color yes = successGreen;
  static const Color no = errorRose;

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [
          primaryAccent.withValues(alpha: 0.8),
          primaryAccent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get successGradient => LinearGradient(
        colors: [
          successGreen.withValues(alpha: 0.8),
          successGreen,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Opacity Variants
  static Color get primaryAccentLight => primaryAccent.withValues(alpha: 0.15);
  static Color get successLight => successGreen.withValues(alpha: 0.15);
  static Color get errorLight => errorRose.withValues(alpha: 0.15);

  // Text Styles
  static TextStyle get headingLarge => const TextStyle(
        color: textHeading,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => const TextStyle(
        color: textHeading,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headingSmall => const TextStyle(
        color: textHeading,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => const TextStyle(
        color: textBody,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => const TextStyle(
        color: textBody,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => const TextStyle(
        color: textBody,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
          width: 1,
        ),
      );

  static BoxDecoration get glowCardDecoration => BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryAccent.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryAccent,
        foregroundColor: textHeading,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  static ButtonStyle get successButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: successGreen,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  static ButtonStyle get errorButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: errorRose,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  // Chip Styles
  static BoxDecoration selectedChipDecoration = BoxDecoration(
    color: successGreen,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: successGreen,
      width: 2,
    ),
  );

  static BoxDecoration unselectedChipDecoration = BoxDecoration(
    color: surfaceLight,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: border,
      width: 1,
    ),
  );
}
