import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_avatar.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_badge.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final sub = member.activeSubscription;
    return GymCard(
      onTap: onTap,
      padding: AppSpacing.paddingAll16,
      child: Row(
        children: [
          GymAvatar(name: member.name, imageUrl: member.imageUrl, size: 48),
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
                      style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (sub != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      _BillingBadge(billingType: sub.billingType),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: _BillingStatusChip(sub: sub),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Icon(PhosphorIcons.caretRight(), size: 20, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _BillingBadge extends StatelessWidget {
  const _BillingBadge({required this.billingType});
  final String billingType;

  @override
  Widget build(BuildContext context) {
    final isPrepaid = billingType == 'prepaid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isPrepaid ? AppColors.success : AppColors.info).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPrepaid ? 'Prepaid' : 'Postpaid',
        style: AppText.labelSmall.copyWith(
          color: isPrepaid ? AppColors.success : AppColors.info,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BillingStatusChip extends StatelessWidget {
  const _BillingStatusChip({required this.sub});
  final MemberSubscription sub;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(sub);
    return Text(
      label,
      style: AppText.labelSmall.copyWith(color: color, fontSize: 10),
      overflow: TextOverflow.ellipsis,
    );
  }

  static (String, Color) _resolve(MemberSubscription sub) {
    switch (sub.billingStatus) {
      case 'paid':
        return ('Fully Paid', AppColors.success);
      case 'prepaid_overdue':
        final days = sub.daysUntilDue?.abs() ?? 0;
        return ('Overdue by $days days', AppColors.error);
      case 'prepaid_due':
        final days = sub.daysUntilDue ?? 0;
        return (days == 0 ? 'Due today' : 'Due in $days days', AppColors.warning);
      case 'prepaid_pending':
        return ('Payment pending', AppColors.textSecondary);
      case 'postpaid_window_open':
        final days = sub.daysUntilDue ?? 0;
        return ('Pay now · $days days left', AppColors.warning);
      case 'postpaid_overdue':
        final days = (sub.daysUntilDue ?? 0).abs();
        return ('Overdue by $days days', AppColors.error);
      case 'postpaid_not_due_yet':
        final days = sub.daysUntilDue ?? 0;
        return ('Due in $days days', AppColors.textSecondary);
      default:
        return ('Active', AppColors.primary);
    }
  }
}
