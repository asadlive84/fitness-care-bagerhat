import 'package:flutter/material.dart';

/// Design token colors for the Fitness Care Bagerhat app.
///
/// All colors are from the brand palette. Use these constants
/// instead of hard-coding hex values anywhere in the codebase.
///
/// See also:
/// - [AppTheme] which builds [ThemeData] using these colors
/// - [AppShadows] for elevation styles tinted with brand colors
abstract final class AppColors {
  // ─── Brand ─────────────────────────────────────────────
  /// Deep forest green — primary brand color.
  static const primary = Color(0xFF1B5E20);

  /// Vibrant green — lighter primary variant.
  static const primaryLight = Color(0xFF4CAF50);

  /// Energetic orange — accent / call-to-action color.
  static const accent = Color(0xFFFF6D00);

  /// Warm orange — lighter accent variant.
  static const accentLight = Color(0xFFFF9E40);

  // ─── Backgrounds ───────────────────────────────────────
  /// Off-white with a subtle green tint — light mode background.
  static const bgLight = Color(0xFFF5F7F0);

  /// Deep dark green-black — dark mode background.
  static const bgDark = Color(0xFF0D1B0F);

  /// Pure white — light mode surface.
  static const surfaceLight = Color(0xFFFFFFFF);

  /// Dark green-black — dark mode surface (cards, sheets).
  static const surfaceDark = Color(0xFF1A2B1C);

  // ─── Status ────────────────────────────────────────────
  /// Green — success, confirmed, active.
  static const success = Color(0xFF00C853);

  /// Amber — warning, expiring soon.
  static const warning = Color(0xFFFFAB00);

  /// Red — error, danger, delete.
  static const error = Color(0xFFD50000);

  /// Blue — informational messages.
  static const info = Color(0xFF0091EA);

  // ─── Text Hierarchy ────────────────────────────────────
  /// Near-black — headings, primary body text (light mode).
  static const textPrimary = Color(0xFF1A1A1A);

  /// Medium gray — secondary descriptions, metadata.
  static const textSecondary = Color(0xFF6B7280);

  /// Light gray — placeholder text, hints.
  static const textHint = Color(0xFF9CA3AF);

  /// Off-white — text on dark backgrounds / gradients.
  static const textOnDark = Color(0xFFF9FAFB);

  // ─── Boundaries ────────────────────────────────────────
  /// Light gray — standard dividers and hair-lines.
  static const divider = Color(0xFFE5E7EB);

  /// Medium gray — form borders and outlines.
  static const border = Color(0xFFD1D5DB);

  // ─── Gradients ─────────────────────────────────────────
  /// Hero gradient for primary cards and buttons.
  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Accent gradient for CTAs and highlights.
  static const gradientOrange = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9E40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark gradient for dark mode hero elements.
  static const gradientDark = LinearGradient(
    colors: [Color(0xFF0D1B0F), Color(0xFF1A2B1C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
