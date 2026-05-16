import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:flutter/material.dart';

/// ## GymSnackbar
///
/// Success / error / info toasts with premium styling.
abstract class GymSnackbar {
  /// Shows a success snackbar.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  /// Shows an error snackbar.
  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error_rounded);
  }

  /// Shows an info snackbar.
  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.info, Icons.info_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppText.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
