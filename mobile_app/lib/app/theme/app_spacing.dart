import 'package:flutter/material.dart';

/// Spacing constants following an 8-point grid system.
///
/// Use these instead of raw numeric values so the app maintains
/// consistent rhythm and is easy to refactor.
abstract final class AppSpacing {
  // ─── Spacing ───────────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;

  // ─── Border Radius ─────────────────────────────────────
  static const r4 = BorderRadius.all(Radius.circular(4));
  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
  static const rFull = BorderRadius.all(Radius.circular(100));

  // ─── Common padding presets ────────────────────────────
  static const paddingH16 = EdgeInsets.symmetric(horizontal: s16);
  static const paddingH24 = EdgeInsets.symmetric(horizontal: s24);
  static const paddingAll12 = EdgeInsets.all(s12);
  static const paddingAll16 = EdgeInsets.all(s16);
  static const paddingAll20 = EdgeInsets.all(s20);
  static const paddingAll24 = EdgeInsets.all(s24);
}
