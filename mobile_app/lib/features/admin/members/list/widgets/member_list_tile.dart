import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_avatar.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_badge.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ## MemberListTile
///
/// Rich list tile for a gym member.
/// Shows avatar, name, phone, status badge, and active plan summary.
class MemberListTile extends StatelessWidget {
  const MemberListTile({
    required this.member,
    required this.onTap,
    super.key,
  });

  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      onTap: onTap,
      padding: AppSpacing.paddingAll16,
      child: Row(
        children: [
          GymAvatar(
            name: member.name,
            imageUrl: member.imageUrl,
            size: 48,
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: AppText.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GymBadge.status(status: member.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.phone(PhosphorIconsStyle.regular),
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      member.phone,
                      style: AppText.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (member.activeSubscription != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Subscription: ${member.activeSubscription!.id.substring(0, 8)}',
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Icon(
            PhosphorIcons.caretRight(),
            size: 20,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}
