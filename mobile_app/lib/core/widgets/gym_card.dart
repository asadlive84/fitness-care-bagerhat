import 'package:fitness_care_bagerhat/app/theme/app_shadows.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// ## GymCard
///
/// Base card with consistent shadow, border radius, and padding.
/// All content cards in the app extend or wrap this widget.
///
/// ### Features
/// - Rounded corners (16px default)
/// - Brand-consistent shadow
/// - Optional tap handler with splash effect
/// - Optional gradient background
/// - Dark mode aware
///
/// ### Usage
/// ```dart
/// GymCard(
///   child: SubscriptionInfo(subscription: sub),
///   onTap: () => router.push(Routes.subscription),
/// )
/// ```
class GymCard extends StatelessWidget {
  const GymCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding,
    this.color,
    this.gradient,
    this.borderRadius,
    this.border,
    this.shadow,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
  });

  /// The card's content.
  final Widget child;

  /// Optional tap handler — adds Material splash effect.
  final VoidCallback? onTap;

  /// Card padding. Defaults to 16px all around.
  final EdgeInsets? padding;

  /// Background color. Defaults to theme surface color.
  final Color? color;

  /// Gradient background. Overrides [color] when provided.
  final Gradient? gradient;

  /// Border radius. Defaults to [AppSpacing.r16].
  final BorderRadius? borderRadius;

  /// Optional border.
  final Border? border;

  /// Shadow. Defaults to [AppShadows.cardShadow].
  final List<BoxShadow>? shadow;

  /// Outer margin.
  final EdgeInsets? margin;

  /// Clip behavior for the card.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? Theme.of(context).cardColor;
    final effectiveRadius = borderRadius ?? AppSpacing.r16;
    final effectiveShadow = shadow ??
        (isDark
            ? [
                const BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : AppShadows.cardShadow);

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveColor : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: effectiveShadow,
      ),
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding ?? AppSpacing.paddingAll16,
        child: child,
      ),
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
