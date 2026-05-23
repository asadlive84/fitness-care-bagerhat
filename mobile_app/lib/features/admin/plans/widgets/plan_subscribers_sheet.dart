import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_response.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bottom sheet listing all active subscribers for a single plan.
///
/// Shows a mini-summary header (member count, total billed, total collected)
/// followed by a scrollable list of subscriber cards with payment progress.
class PlanSubscribersSheet extends StatelessWidget {
  const PlanSubscribersSheet({
    required this.planName,
    required this.financials,
    required this.subscribers,
    super.key,
  });

  final String planName;
  final PlanFinancials financials;
  final List<PlanSubscriberInfo> subscribers;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Mini summary strip ─────────────────────────────────────────────
        _SummaryStrip(financials: financials, count: subscribers.length),
        const SizedBox(height: AppSpacing.s16),

        // ── List ──────────────────────────────────────────────────────────
        if (subscribers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s32),
            child: Center(
              child: Column(
                children: [
                  Icon(PhosphorIcons.usersThree(),
                      size: 40, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.s12),
                  Text('No active subscribers',
                      style: AppText.bodyMedium
                          .copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subscribers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) =>
                _SubscriberCard(sub: subscribers[i]),
          ),

        const SizedBox(height: AppSpacing.s16),
      ],
    );
  }
}

// ── Summary strip ─────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.financials, required this.count});
  final PlanFinancials financials;
  final int count;

  @override
  Widget build(BuildContext context) {
    final rate = financials.collectionRate;
    final isFullyCollected =
        financials.totalDue <= 0 && financials.totalBilled > 0;

    return Container(
      padding: AppSpacing.paddingAll16,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: AppSpacing.r16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.users(),
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$count active member${count == 1 ? '' : 's'}',
                    style: AppText.titleSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              if (isFullyCollected)
                _StatusBadge('Fully Collected', AppColors.success)
              else if (financials.totalDue > 0)
                _StatusBadge(
                    '${financials.totalDue.toBDT()} due', AppColors.error),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: AppSpacing.rFull,
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(
                isFullyCollected ? AppColors.success : AppColors.accent,
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AmountLabel('Billed',
                  financials.totalBilled.toBDT(), AppColors.textPrimary),
              _AmountLabel('Collected',
                  financials.totalCollected.toBDT(), AppColors.success,
                  align: CrossAxisAlignment.center),
              _AmountLabel('Due', financials.totalDue.toBDT(),
                  financials.totalDue > 0
                      ? AppColors.error
                      : AppColors.textHint,
                  align: CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel(this.label, this.value, this.color,
      {this.align = CrossAxisAlignment.start});
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: align,
        children: [
          Text(label,
              style: AppText.labelSmall
                  .copyWith(color: AppColors.textHint, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: AppText.bodyMedium
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppSpacing.rFull,
        ),
        child: Text(label,
            style: AppText.labelSmall.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      );
}

// ── Subscriber card ───────────────────────────────────────────────────────────

class _SubscriberCard extends StatelessWidget {
  const _SubscriberCard({required this.sub});
  final PlanSubscriberInfo sub;

  @override
  Widget build(BuildContext context) {
    final rate = sub.subscriptionPrice > 0
        ? (sub.moneyPaid / sub.subscriptionPrice).clamp(0.0, 1.0)
        : 0.0;
    final isFullyPaid = sub.moneyLeft <= 0;
    final daysLeft = sub.subscriptionEndDate
        .difference(DateTime.now())
        .inDays;
    final isExpired = daysLeft < 0;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close the bottom sheet first
        context.push(Routes.adminMemberDetail(sub.memberId));
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: AppSpacing.s12, horizontal: AppSpacing.s16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Member row ───────────────────────────────────────────────
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  sub.memberName.isNotEmpty
                      ? sub.memberName[0].toUpperCase()
                      : '?',
                  style: AppText.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),

              // Name + phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.memberName, style: AppText.titleSmall),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(PhosphorIcons.phone(),
                            size: 12,
                            color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(sub.phone,
                            style: AppText.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),

              // Price + status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(sub.subscriptionPrice.toBDT(),
                      style: AppText.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  _paymentBadge(isFullyPaid, sub.moneyLeft),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s12),

          // ── Dates row ────────────────────────────────────────────────
          Row(
            children: [
              Icon(PhosphorIcons.calendarBlank(),
                  size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                '${sub.subscriptionStartDate.toShortDate()} → '
                '${sub.subscriptionEndDate.toDisplay()}',
                style: AppText.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              // Days remaining / expired
              if (isExpired)
                Text('Expired ${(-daysLeft)}d ago',
                    style: AppText.labelSmall
                        .copyWith(color: AppColors.error, fontSize: 10))
              else
                Text('$daysLeft days left',
                    style: AppText.labelSmall.copyWith(
                        color: daysLeft <= 7
                            ? AppColors.warning
                            : AppColors.textHint,
                        fontSize: 10)),
            ],
          ),

          const SizedBox(height: AppSpacing.s8),

          // ── Payment progress bar ─────────────────────────────────────
          ClipRRect(
            borderRadius: AppSpacing.rFull,
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(
                isFullyPaid ? AppColors.success : AppColors.accent,
              ),
              minHeight: 5,
            ),
          ),

          const SizedBox(height: AppSpacing.s8),

          // ── Paid / Due amounts ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.checkCircle(),
                      size: 13, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text('Paid ${sub.moneyPaid.toBDT()}',
                      style: AppText.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              if (!isFullyPaid)
                Row(
                  children: [
                    Icon(PhosphorIcons.warning(),
                        size: 13, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text('Due ${sub.moneyLeft.toBDT()}',
                        style: AppText.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _paymentBadge(bool isFullyPaid, double moneyLeft) {
    if (isFullyPaid) {
      return _StatusBadge('Paid', AppColors.success);
    }
    return _StatusBadge('Partial', AppColors.warning);
  }
}
