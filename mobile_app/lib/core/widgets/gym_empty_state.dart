import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// ## GymEmptyState
///
/// Lottie illustration + context-aware message + action button.
/// Use this when a list is empty or a search returns no results.
class GymEmptyState extends StatelessWidget {
  const GymEmptyState({
    required this.message,
    required this.animationPath,
    super.key,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  /// The primary message explaining why the state is empty.
  final String message;

  /// Path to the Lottie JSON animation.
  final String animationPath;

  /// Optional bold title.
  final String? title;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional callback for the action button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAll24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                animationPath,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.5),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            if (title != null) ...[
              Text(
                title!,
                style: AppText.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
            Text(
              message,
              style: AppText.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.s32),
              GymButton.secondary(
                label: actionLabel!,
                onPressed: onAction,
                isExpanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
