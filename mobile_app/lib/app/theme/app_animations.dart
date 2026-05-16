import 'package:flutter/material.dart';

/// Animation duration and curve presets.
///
/// These ensure consistent motion across the app, giving it a
/// polished, premium feel. Use these instead of ad-hoc Duration/Curves.
abstract final class AppAnimations {
  // ─── Durations ─────────────────────────────────────────
  /// Fast micro-interactions (toggles, ripples).
  static const dFast = Duration(milliseconds: 150);

  /// Standard transitions (tabs, expansion).
  static const dNormal = Duration(milliseconds: 280);

  /// Slow, deliberate animations (page transitions, chart draw-in).
  static const dSlow = Duration(milliseconds: 420);

  /// Page route transition duration.
  static const dPage = Duration(milliseconds: 350);

  // ─── Curves ────────────────────────────────────────────
  /// Enter transition — starts fast, eases out.
  static const curveEnter = Curves.easeOutCubic;

  /// Exit transition — starts slow, accelerates out.
  static const curveExit = Curves.easeInCubic;

  /// Springy overshoot — success animations, FAB pop-in.
  static const curveSpring = Curves.elasticOut;

  /// Bouncy finish — playful elements, badges.
  static const curveBounce = Curves.bounceOut;
}
