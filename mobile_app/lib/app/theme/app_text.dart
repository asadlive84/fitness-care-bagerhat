import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for the Fitness Care Bagerhat app.
///
/// Primary font: **Plus Jakarta Sans** (headings, body).
/// Numeric font: **Inter** (counters, amounts, charts).
///
/// All sizes follow Material 3 type scale conventions.
abstract final class AppText {
  // ─── Display ───────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        height: 1.12,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        height: 1.16,
      );

  // ─── Headline ──────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.28,
      );

  // ─── Title ─────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.50,
        letterSpacing: 0.15,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
      );

  // ─── Body ──────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.50,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.50,
      );

  // ─── Label ─────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.45,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.5,
      );

  // ─── Mono (numbers, currency, counters) ────────────────
  static TextStyle get mono => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get monoSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get monoLarge => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
      );
}
