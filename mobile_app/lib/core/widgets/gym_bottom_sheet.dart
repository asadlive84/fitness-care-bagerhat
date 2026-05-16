import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:flutter/material.dart';

/// ## GymBottomSheet
///
/// Draggable bottom sheet wrapper with consistent styling.
class GymBottomSheet extends StatelessWidget {
  const GymBottomSheet({
    required this.child,
    super.key,
    this.title,
    this.onClose,
  });

  /// The content of the bottom sheet.
  final Widget child;

  /// Optional title displayed at the top.
  final String? title;

  /// Called when the sheet is closed.
  final VoidCallback? onClose;

  /// Static helper to show the sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GymBottomSheet(
        title: title,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s24,
                AppSpacing.s8,
                AppSpacing.s12,
                AppSpacing.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppText.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      Navigator.pop(context);
                      onClose?.call();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Flexible(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingAll24,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
