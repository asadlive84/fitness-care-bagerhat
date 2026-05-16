import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_shadows.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ## GymButton
///
/// Primary action button with gradient background and subtle shadow.
/// Supports loading state (spinner replaces label) and haptic feedback.
///
/// ### Variants
/// - [GymButton.primary] — green gradient + white text
/// - [GymButton.secondary] — outlined green border + green text
/// - [GymButton.danger] — red gradient
/// - [GymButton.text] — no background, green text
/// - [GymButton.icon] — circular icon button
///
/// ### Usage
/// ```dart
/// GymButton(
///   label: 'Create Member',
///   icon: PhosphorIcons.userPlus(),
///   onPressed: controller.submit,
///   isLoading: state.isLoading,
/// )
/// ```
class GymButton extends StatelessWidget {
  const GymButton({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.elevation = true,
  }) : _variant = _GymButtonVariant.primary;

  const GymButton.primary({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  })  : _variant = _GymButtonVariant.primary,
        gradient = null,
        backgroundColor = null,
        foregroundColor = null,
        borderColor = null,
        elevation = true;

  const GymButton.secondary({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  })  : _variant = _GymButtonVariant.secondary,
        gradient = null,
        backgroundColor = null,
        foregroundColor = null,
        borderColor = null,
        elevation = false;

  const GymButton.danger({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  })  : _variant = _GymButtonVariant.danger,
        gradient = null,
        backgroundColor = null,
        foregroundColor = null,
        borderColor = null,
        elevation = true;

  const GymButton.text({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  })  : _variant = _GymButtonVariant.text,
        gradient = null,
        backgroundColor = null,
        foregroundColor = null,
        borderColor = null,
        elevation = false;

  /// The button label text.
  final String label;

  /// Called when the button is tapped. Null disables the button.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final Widget? icon;

  /// Shows a spinner and disables tap when true.
  final bool isLoading;

  /// Whether the button expands to fill its parent width.
  final bool isExpanded;

  /// Custom gradient (overrides variant gradient).
  final Gradient? gradient;

  /// Custom background color.
  final Color? backgroundColor;

  /// Custom foreground (text/icon) color.
  final Color? foregroundColor;

  /// Custom border color (secondary variant).
  final Color? borderColor;

  /// Whether to show the drop shadow.
  final bool elevation;

  final _GymButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onPressed == null || isLoading;

    final effectiveGradient = _resolveGradient(isDark);
    final effectiveFg = _resolveForeground(isDark);
    final effectiveBorder = _resolveBorder(isDark);

    Widget child;

    if (isLoading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: effectiveFg,
        ),
      );
    } else {
      final textWidget = Text(
        label,
        style: AppText.labelLarge.copyWith(color: effectiveFg),
      );

      if (icon != null) {
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(color: effectiveFg, size: 20),
              child: icon!,
            ),
            const SizedBox(width: AppSpacing.s8),
            textWidget,
          ],
        );
      } else {
        child = textWidget;
      }
    }

    final buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: _variant != _GymButtonVariant.secondary &&
                _variant != _GymButtonVariant.text
            ? (isDisabled ? null : effectiveGradient)
            : null,
        color: _variant == _GymButtonVariant.secondary ||
                _variant == _GymButtonVariant.text
            ? Colors.transparent
            : (isDisabled ? Colors.grey.shade300 : null),
        borderRadius: AppSpacing.r12,
        border: effectiveBorder != null
            ? Border.all(color: effectiveBorder, width: 1.5)
            : null,
        boxShadow:
            elevation && !isDisabled ? AppShadows.buttonShadow : null,
      ),
      child: Center(child: child),
    );

    final wrappedButton = GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed?.call();
            },
      child: isExpanded
          ? buttonContent
          : IntrinsicWidth(child: buttonContent),
    );

    return wrappedButton;
  }

  Gradient? _resolveGradient(bool isDark) {
    if (gradient != null) return gradient;
    return switch (_variant) {
      _GymButtonVariant.primary => AppColors.gradientGreen,
      _GymButtonVariant.danger => const LinearGradient(
          colors: [Color(0xFFD50000), Color(0xFFFF1744)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      _ => null,
    };
  }

  Color _resolveForeground(bool isDark) {
    if (foregroundColor != null) return foregroundColor!;
    return switch (_variant) {
      _GymButtonVariant.primary => Colors.white,
      _GymButtonVariant.secondary =>
        isDark ? AppColors.primaryLight : AppColors.primary,
      _GymButtonVariant.danger => Colors.white,
      _GymButtonVariant.text =>
        isDark ? AppColors.primaryLight : AppColors.primary,
    };
  }

  Color? _resolveBorder(bool isDark) {
    if (borderColor != null) return borderColor;
    if (_variant == _GymButtonVariant.secondary) {
      return isDark ? AppColors.primaryLight : AppColors.primary;
    }
    return null;
  }
}

enum _GymButtonVariant { primary, secondary, danger, text }
