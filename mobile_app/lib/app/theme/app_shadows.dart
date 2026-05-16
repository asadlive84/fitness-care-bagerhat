import 'package:flutter/material.dart';

/// Shadow presets for the Fitness Care Bagerhat app.
///
/// Three levels of elevation:
/// - [cardShadow] — resting cards, tiles
/// - [floatShadow] — floating action buttons, elevated sheets
/// - [buttonShadow] — primary action buttons
///
/// Shadows are tinted with green for brand consistency.
abstract final class AppShadows {
  /// Subtle shadow for cards sitting on a surface.
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Elevated shadow for floating elements (FABs, bottom sheets).
  /// Tinted green for brand cohesion.
  static const floatShadow = [
    BoxShadow(
      color: Color(0x1A1B5E20),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];

  /// Button shadow — strong brand-tinted elevation for CTAs.
  static const buttonShadow = [
    BoxShadow(
      color: Color(0x3D1B5E20),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
