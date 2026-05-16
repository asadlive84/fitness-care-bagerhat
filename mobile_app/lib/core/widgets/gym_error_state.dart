import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:flutter/material.dart';

/// ## GymErrorState
///
/// Error message with a retry button.
/// Use this when an API call fails or a network error occurs.
class GymErrorState extends StatelessWidget {
  const GymErrorState({
    required this.message,
    super.key,
    this.onRetry,
    this.title = 'Oops!',
  });

  /// The error message to display.
  final String message;

  /// Called when the retry button is tapped.
  final VoidCallback? onRetry;

  /// Bold title for the error.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAll24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              title,
              style: AppText.headlineMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              message,
              style: AppText.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s32),
              GymButton.primary(
                label: 'Try Again',
                onPressed: onRetry,
                isExpanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
