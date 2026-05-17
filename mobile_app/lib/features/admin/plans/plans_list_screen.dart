import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_bottom_sheet.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/widgets/plan_subscribers_sheet.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_response.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/widgets/plan_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PlansListScreen extends ConsumerWidget {
  const PlansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plansControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Plans'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.plus()),
            onPressed: () => _showPlanForm(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(plansControllerProvider.notifier).load(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _PeriodSelector(state: state),
                  if (!state.isLoading && state.error == null)
                    _SummaryCard(summary: state.summary, state: state),
                ],
              ),
            ),
            if (state.isLoading)
              SliverPadding(
                padding: AppSpacing.paddingAll16,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.s12),
                      child: GymShimmer.card(height: 130),
                    ),
                    childCount: 4,
                  ),
                ),
              )
            else if (state.error != null)
              SliverFillRemaining(
                child: GymErrorState(
                  message: state.error!.message,
                  onRetry: () =>
                      ref.read(plansControllerProvider.notifier).load(),
                ),
              )
            else if (state.enrichedPlans.isEmpty)
              SliverFillRemaining(
                child: GymEmptyState(
                  message: 'No plans yet. Tap + to create the first one.',
                  animationPath: 'assets/animations/empty_members.json',
                  actionLabel: 'Create Plan',
                  onAction: () => _showPlanForm(context, ref),
                ),
              )
            else
              SliverPadding(
                padding: AppSpacing.paddingAll16,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = state.enrichedPlans[i];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.s12),
                        child: _PlanCard(
                          enriched: p,
                          onEdit: () =>
                              _showPlanForm(context, ref, plan: p.plan),
                          onDelete: () => _confirmDelete(context, ref, p.plan),
                        ),
                      );
                    },
                    childCount: state.enrichedPlans.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlanForm(BuildContext context, WidgetRef ref, {Plan? plan}) {
    GymBottomSheet.show<void>(
      context: context,
      title: plan == null ? 'New Plan' : 'Edit Plan',
      child: PlanForm(plan: plan),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Plan plan) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Delete "${plan.name}"? This cannot be undone.\n\n'
          'Plans linked to active subscriptions cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref
                  .read(plansControllerProvider.notifier)
                  .deletePlan(plan.id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({required this.state});
  final PlansState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(plansControllerProvider.notifier);

    final labels = {
      PlanPeriod.monthly: 'Monthly',
      PlanPeriod.lifetime: 'Lifetime',
      PlanPeriod.custom: 'Custom',
    };

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          // Pill row
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.4),
              borderRadius: AppSpacing.r20,
            ),
            child: Row(
              children: PlanPeriod.values.map((p) {
                final isSelected = state.period == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (p == PlanPeriod.custom) {
                        _pickCustomRange(context, ref);
                      } else {
                        ctrl.setPeriod(p);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.white : Colors.transparent,
                        borderRadius: AppSpacing.r16,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        labels[p]!,
                        textAlign: TextAlign.center,
                        style: AppText.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Month navigator
          if (state.period == PlanPeriod.monthly) ...[
            const SizedBox(height: AppSpacing.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: ctrl.prevMonth,
                  icon: Icon(PhosphorIcons.caretLeft(), size: 18),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: AppSpacing.s20),
                Text(
                  DateFormat('MMMM yyyy').format(state.selectedMonth),
                  style: AppText.titleSmall,
                ),
                const SizedBox(width: AppSpacing.s20),
                IconButton(
                  onPressed: ctrl.nextMonth,
                  icon: Icon(PhosphorIcons.caretRight(), size: 18),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],

          // Custom range label
          if (state.period == PlanPeriod.custom &&
              state.customFrom != null &&
              state.customTo != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.calendarBlank(),
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('dd MMM yyyy').format(state.customFrom!)} – '
                  '${DateFormat('dd MMM yyyy').format(state.customTo!)}',
                  style: AppText.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _pickCustomRange(context, ref),
                  child: Text('Change',
                      style: AppText.labelSmall
                          .copyWith(color: AppColors.primary, fontSize: 11)),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.s12),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(plansControllerProvider.notifier);
    final now = DateTime.now();

    final from = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select start date',
    );
    if (from == null || !context.mounted) return;

    final to = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: from,
      lastDate: now,
      helpText: 'Select end date',
    );
    if (to == null) return;

    ctrl.setCustomRange(from, to);
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.state});
  final PlanSummary summary;
  final PlansState state;

  String get _label {
    switch (state.period) {
      case PlanPeriod.lifetime:
        return 'All Time';
      case PlanPeriod.monthly:
        return DateFormat('MMMM yyyy').format(state.selectedMonth);
      case PlanPeriod.custom:
        if (state.customFrom != null && state.customTo != null) {
          return '${DateFormat('dd MMM').format(state.customFrom!)} – '
              '${DateFormat('dd MMM yyyy').format(state.customTo!)}';
        }
        return 'Custom Period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = summary.collectionRate;
    final isFullyCollected =
        summary.totalDue <= 0 && summary.totalBilled > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: AppSpacing.paddingAll20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.r20,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_label,
                  style: AppText.labelSmall
                      .copyWith(color: Colors.white70, letterSpacing: 0.4)),
              if (summary.subscriptionsStarted > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppSpacing.rFull,
                  ),
                  child: Text(
                    '${summary.subscriptionsStarted} sold',
                    style: AppText.labelSmall
                        .copyWith(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            summary.totalBilled.toBDT(),
            style: AppText.headlineLarge.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text('Total Billed',
              style:
                  AppText.bodySmall.copyWith(color: Colors.white60)),
          const SizedBox(height: AppSpacing.s20),

          // Progress bar
          ClipRRect(
            borderRadius: AppSpacing.rFull,
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(
                isFullyCollected
                    ? const Color(0xFF69F0AE) // bright green on dark bg
                    : Colors.white,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Tile('COLLECTED', summary.totalCollected.toBDT(),
                  Colors.white),
              _Tile('DUE', summary.totalDue.toBDT(),
                  summary.totalDue > 0
                      ? const Color(0xFFFFCDD2)
                      : Colors.white70,
                  align: CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.color,
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
              style: AppText.labelSmall.copyWith(
                  color: Colors.white60, fontSize: 10, letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(value,
              style: AppText.titleMedium
                  .copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      );
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.enriched,
    required this.onEdit,
    required this.onDelete,
  });
  final PlanWithSubscribers enriched;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  void _openSubscribers(BuildContext context) {
    GymBottomSheet.show<void>(
      context: context,
      title: '${enriched.plan.name} · Subscribers',
      child: PlanSubscribersSheet(
        planName: enriched.plan.name,
        financials: enriched.financials,
        subscribers: enriched.subscribers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = enriched.plan;
    final fin = enriched.financials;
    final subs = enriched.subscribers;
    final rate = fin.collectionRate;
    final isFullyPaid = fin.totalDue <= 0 && fin.totalBilled > 0;
    final isPrepaid = plan.billingType == 'prepaid';

    return GymCard(
      padding: AppSpacing.paddingAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: Text(plan.name, style: AppText.titleMedium)),
              _PillBadge(
                label: isPrepaid ? 'Prepaid' : 'Postpaid',
                color: isPrepaid ? AppColors.success : AppColors.info,
              ),
              const SizedBox(width: AppSpacing.s8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.r8,
                  ),
                  child: Icon(PhosphorIcons.trash(),
                      size: 16, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),

          // ── Duration + price + member count tap ─────────────────────────
          Row(
            children: [
              Icon(PhosphorIcons.clock(), size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('${plan.durationDays} days',
                  style: AppText.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.s12),
              Icon(PhosphorIcons.money(), size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(plan.defaultPrice.toBDT(),
                  style: AppText.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              if (subs.isNotEmpty)
                GestureDetector(
                  onTap: () => _openSubscribers(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.rFull,
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.users(),
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${subs.length} member${subs.length == 1 ? '' : 's'}',
                          style: AppText.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 2),
                        Icon(PhosphorIcons.arrowRight(),
                            size: 10, color: AppColors.primary),
                      ],
                    ),
                  ),
                )
              else
                Text('No active members',
                    style: AppText.labelSmall
                        .copyWith(color: AppColors.textHint, fontSize: 11)),
            ],
          ),

          // ── Financials ──────────────────────────────────────────────────
          if (fin.totalBilled > 0) ...[
            const SizedBox(height: AppSpacing.s12),
            ClipRRect(
              borderRadius: AppSpacing.rFull,
              child: LinearProgressIndicator(
                value: rate,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(
                  isFullyPaid ? AppColors.success : AppColors.accent,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: [
                _FinStat('Billed', fin.totalBilled.toBDT(),
                    AppColors.textPrimary),
                const SizedBox(width: AppSpacing.s16),
                _FinStat('Collected', fin.totalCollected.toBDT(),
                    AppColors.success),
                const SizedBox(width: AppSpacing.s16),
                _FinStat(
                  'Due',
                  fin.totalDue.toBDT(),
                  fin.totalDue > 0 ? AppColors.error : AppColors.textHint,
                ),
                const Spacer(),
                if (fin.subscriptionsStarted > 0)
                  Text('${fin.subscriptionsStarted} sold',
                      style: AppText.labelSmall
                          .copyWith(color: AppColors.textHint, fontSize: 10)),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.s8),
            Text('No transactions in this period',
                style:
                    AppText.bodySmall.copyWith(color: AppColors.textHint)),
          ],

          // ── Edit button ─────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.s12),
          const Divider(height: 1),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Text('Edit Plan',
                style: AppText.labelSmall.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _FinStat extends StatelessWidget {
  const _FinStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.labelSmall
                  .copyWith(color: AppColors.textHint, fontSize: 10)),
          Text(value,
              style: AppText.bodyMedium
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      );
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppSpacing.rFull,
        ),
        child: Text(label,
            style: AppText.labelSmall.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      );
}
