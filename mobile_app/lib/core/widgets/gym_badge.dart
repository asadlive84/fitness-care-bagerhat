import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:flutter/material.dart';

/// Status badge chip for active/inactive/expiring/expired states.
class GymBadge extends StatelessWidget {
  const GymBadge({required this.status, super.key})
      : _label = null,
        _color = null;

  const GymBadge.custom({
    required String label,
    required Color color,
    super.key,
  })  : status = null,
        _label = label,
        _color = color;

  /// Helper constructor for member status.
  factory GymBadge.status({required String status, Key? key}) {
    final s = switch (status.toLowerCase()) {
      'active' => BadgeStatus.active,
      'inactive' => BadgeStatus.inactive,
      'expiring' => BadgeStatus.expiring,
      'expired' => BadgeStatus.expired,
      _ => BadgeStatus.inactive,
    };
    return GymBadge(status: s, key: key);
  }

  final BadgeStatus? status;
  final String? _label;
  final Color? _color;

  @override
  Widget build(BuildContext context) {
    final label = _label ?? status!.label;
    final color = _color ?? status!.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppSpacing.rFull,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AppText.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

enum BadgeStatus {
  active, inactive, expiring, expired;

  String get label => switch (this) { active => 'Active', inactive => 'Inactive', expiring => 'Expiring', expired => 'Expired' };
  Color get color => switch (this) { active => AppColors.success, inactive => AppColors.textHint, expiring => AppColors.warning, expired => AppColors.error };
}
