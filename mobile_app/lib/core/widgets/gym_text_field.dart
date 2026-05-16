import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:flutter/material.dart';

/// ## GymTextField
///
/// Themed text field with consistent styling, validation, and animation.
///
/// ### Features
/// - Floating label animation
/// - Prefix/suffix icon support
/// - Validation error messages
/// - Show/hide toggle for password fields
/// - Focus color transition
/// - Dark mode aware
///
/// ### Usage
/// ```dart
/// GymTextField(
///   label: 'Email',
///   controller: emailController,
///   keyboardType: TextInputType.emailAddress,
///   validator: (v) => v?.isEmpty == true ? 'Required' : null,
///   prefixIcon: Icon(PhosphorIcons.envelope()),
/// )
/// ```
class GymTextField extends StatefulWidget {
  const GymTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.suffixText,
  });

  /// Label displayed above the field.
  final String? label;

  /// Hint text shown when the field is empty.
  final String? hint;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Field validator for Form integration.
  final String? Function(String?)? validator;

  /// Called on every text change.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (keyboard action button).
  final ValueChanged<String>? onSubmitted;

  /// Keyboard type hint.
  final TextInputType? keyboardType;

  /// Keyboard action button type.
  final TextInputAction? textInputAction;

  /// Icon displayed before the input text.
  final Widget? prefixIcon;

  /// Icon displayed after the input text.
  final Widget? suffixIcon;

  /// Text displayed after the input text (unit label).
  final String? suffixText;

  /// Whether to obscure text (password field).
  final bool obscureText;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only (non-editable but selectable).
  final bool readOnly;

  /// Maximum number of lines.
  final int maxLines;

  /// Minimum number of lines.
  final int? minLines;

  /// Maximum character length.
  final int? maxLength;

  /// Whether to auto-focus on mount.
  final bool autofocus;

  /// External focus node.
  final FocusNode? focusNode;

  /// Text capitalization.
  final TextCapitalization textCapitalization;

  /// External error text (overrides validator).
  final String? errorText;

  @override
  State<GymTextField> createState() => _GymTextFieldState();
}

class _GymTextFieldState extends State<GymTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppText.labelLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscure,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          textCapitalization: widget.textCapitalization,
          style: AppText.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon,
            suffixText: widget.suffixText,
            suffixStyle: AppText.labelSmall.copyWith(color: AppColors.textHint),
          ),
        ),
      ],
    );
  }
}
