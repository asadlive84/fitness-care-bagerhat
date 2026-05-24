import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_shadows.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_avatar.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_badge.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_bottom_sheet.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/member_detail_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/widgets/assign_plan_sheet.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/widgets/update_subscription_sheet.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/widgets/compose_message_sheet.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/widgets/record_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:printing/printing.dart';

import 'widgets/member_form_pdf.dart';

/// Returns the active subscription embedded in the member detail response.
///
/// The admin member-detail GET endpoint now returns active_subscription with
/// plan info and payment totals — no separate subscriptions API call needed.
///
/// Invalidate by calling `ref.invalidate(memberDetailControllerProvider(memberId))`
/// after assigning or updating a subscription.
final memberActiveSubProvider = FutureProvider.autoDispose
    .family<MemberSubscription?, String>((ref, memberId) async {
  final memberAsync = ref.watch(memberDetailControllerProvider(memberId));
  return memberAsync.valueOrNull?.activeSubscription;
});

/// Calculates the total paid amount for a specific subscription.
final subscriptionTotalPaidProvider = FutureProvider.autoDispose
    .family<double, (String memberId, String subscriptionId)>((ref, arg) async {
  final response =
      await ref.read(paymentRepositoryProvider).list(memberId: arg.$1);
  final payments = response.data ?? [];
  return payments
      .where((p) => p.subscriptionId == arg.$2)
      .fold<double>(0.0, (sum, p) => sum + p.amount);
});

/// ## MemberDetailScreen
///
/// Admin view showing detailed information about a member.
/// Includes subscription, actions, reset password, delete.
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memberDetailControllerProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        actions: [
          state.when(
            data: (member) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.export()),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('Form Preview')),
                          body: PdfPreview(
                            build: (format) => MemberFormPdf.generate(member),
                            allowSharing: true,
                            allowPrinting: true,
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            pdfFileName: 'member_form_${member.name.replaceAll(' ', '_')}.pdf',
                          ),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.pencilSimple()),
                  onPressed: () => context.push(Routes.adminMemberEdit(member.id),
                      extra: member),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          PopupMenuButton<String>(
            icon: Icon(PhosphorIcons.dotsThreeVertical()),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(children: [
                  Icon(PhosphorIcons.key(), size: 20),
                  const SizedBox(width: AppSpacing.s12),
                  const Text('Reset Password'),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(PhosphorIcons.trash(), size: 20, color: AppColors.error),
                  const SizedBox(width: AppSpacing.s12),
                  Text('Delete Member',
                      style: const TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
            onSelected: (value) {
              final member = state.valueOrNull;
              if (member == null) return;
              if (value == 'reset') {
                _showResetPasswordDialog(context, ref, member);
              } else if (value == 'delete') {
                _showDeleteDialog(context, ref, member);
              }
            },
          ),
        ],
      ),
      body: state.when(
        loading: () => const _LoadingState(),
        error: (error, _) => GymErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(memberDetailControllerProvider(id).notifier).load(),
        ),
        data: (member) => _Content(member: member, screenId: id),
      ),
    );
  }

  void _showResetPasswordDialog(
      BuildContext context, WidgetRef ref, Member member) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ResetPasswordDialog(
        member: member,
        onConfirm: () async {
          try {
            final tempPass = await ref
                .read(memberRepositoryProvider)
                .resetPassword(member.id);
            if (ctx.mounted) {
              Navigator.pop(ctx);
              _showTempPasswordDialog(context, member.name, tempPass);
            }
          } catch (e) {
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }

  void _showTempPasswordDialog(
      BuildContext context, String name, String tempPass) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Password Reset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New temporary password for $name:"),
            const SizedBox(height: AppSpacing.s12),
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingAll16,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: AppSpacing.r8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tempPass, style: AppText.mono),
                  const SizedBox(width: AppSpacing.s8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tempPass));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Share this with the member. They must change it on next login.',
              style: AppText.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, Member member) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text(
          'Are you sure you want to permanently delete ${member.name}? '
          'This will remove all their data including subscriptions, payments, and logs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(memberRepositoryProvider)
                    .deleteMember(member.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) context.pop();
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
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

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.member, required this.onConfirm});
  final Member member;
  final Future<void> Function() onConfirm;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Text(
        'This will generate a new temporary password for ${widget.member.name}. '
        'They will be required to change it on their next login.',
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await widget.onConfirm();
                  if (mounted) setState(() => _isLoading = false);
                },
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reset'),
        ),
      ],
    );
  }
}

// ─── Content ─────────────────────────────────────────────────────────────────

class _Content extends ConsumerWidget {
  const _Content({required this.member, required this.screenId});
  final Member member;
  final String screenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _Header(member: member, screenId: screenId),
          ),
          const SliverToBoxAdapter(
            child: TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Subscriptions'),
                Tab(text: 'Payments'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _OverviewTab(member: member, screenId: screenId),
            _SubscriptionsTab(memberId: member.id, screenId: screenId),
            _PaymentsTab(memberId: member.id),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.member, required this.screenId});
  final Member member;
  final String screenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSubAsync = ref.watch(memberActiveSubProvider(member.id));
    final activeSub = activeSubAsync.valueOrNull;

    return Padding(
      padding: AppSpacing.paddingAll24,
      child: Column(
        children: [
          GymAvatar(name: member.name, imageUrl: member.profilePictureUrl, size: 90),
          const SizedBox(height: AppSpacing.s16),
          Text(member.name, style: AppText.headlineLarge),
          Text(member.phone,
              style: AppText.bodyLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s8),
          GymBadge.status(status: member.status),
          const SizedBox(height: AppSpacing.s24),
          Row(
            children: [
              Expanded(
                child: GymButton.secondary(
                  label: 'Message',
                  icon: Icon(PhosphorIcons.chatTeardropDots()),
                  onPressed: () => GymBottomSheet.show<void>(
                    context: context,
                    title: 'Send Message',
                    child: ComposeMessageSheet(initialRecipient: member),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: GymButton.secondary(
                  label: 'Payment',
                  icon: Icon(PhosphorIcons.money()),
                  onPressed: () {
                    if (activeSub == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please assign a plan before recording a payment.'),
                        ),
                      );
                      return;
                    }
                    GymBottomSheet.show<bool?>(
                      context: context,
                      title: 'Record Payment',
                      child: RecordPaymentSheet(
                        memberId: member.id,
                        memberName: member.name,
                        subscriptionId: activeSub.id,
                      ),
                    ).then((ok) {
                      if (ok == true) {
                        ref
                            .read(memberDetailControllerProvider(screenId).notifier)
                            .load();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.member, required this.screenId});
  final Member member;
  final String screenId;

  void _refreshSub(WidgetRef ref) {
    // Reload member detail — active_subscription is now embedded in the response.
    ref.read(memberDetailControllerProvider(screenId).notifier).load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(memberActiveSubProvider(member.id));

    return SingleChildScrollView(
      padding: AppSpacing.paddingAll24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active subscription card ─────────────────────────────────
          subAsync.when(
            loading: () => const GymShimmer.card(height: 160),
            error: (_, __) => const SizedBox.shrink(), // non-fatal; show nothing
            data: (activeSub) {
              if (activeSub != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SubscriptionCard(
                      memberId: member.id,
                      subscription: activeSub,
                      onEdit: () => GymBottomSheet.show<bool?>(
                        context: context,
                        title: 'Update Subscription',
                        child: UpdateSubscriptionSheet(
                          memberId: member.id,
                          subscription: activeSub,
                        ),
                      ).then((ok) {
                        if (ok == true) _refreshSub(ref);
                      }),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    GymButton.secondary(
                      label: 'Replace Plan',
                      icon: Icon(PhosphorIcons.arrowsClockwise()),
                      onPressed: () => GymBottomSheet.show<bool?>(
                        context: context,
                        title: 'Assign New Plan',
                        child: AssignPlanSheet(memberId: member.id),
                      ).then((ok) {
                        if (ok == true) _refreshSub(ref);
                      }),
                    ),
                  ],
                );
              }
              return GymCard(
                padding: EdgeInsets.all(AppSpacing.s24),
                child: Column(
                  children: [
                    Icon(PhosphorIcons.warningCircle(),
                        size: 40, color: AppColors.warning),
                    const SizedBox(height: AppSpacing.s12),
                    Text('No active subscription', style: AppText.titleMedium),
                    const SizedBox(height: AppSpacing.s24),
                    GymButton.primary(
                      label: 'Assign Plan',
                      onPressed: () => GymBottomSheet.show<bool?>(
                        context: context,
                        title: 'Assign Membership Plan',
                        child: AssignPlanSheet(memberId: member.id),
                      ).then((ok) {
                        if (ok == true) _refreshSub(ref);
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s24),
          _AiNutritionCard(member: member, screenId: screenId),
          const SizedBox(height: AppSpacing.s32),
          Text('Member Info', style: AppText.titleMedium),
          const SizedBox(height: AppSpacing.s16),
          _DetailRow(
            icon: PhosphorIcons.calendar(),
            label: 'Member Since',
            value: member.joinDate?.toDisplay() ?? 'N/A',
          ),
          if (member.dateOfBirth != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.cake(),
              label: 'Date of Birth',
              value: '${member.dateOfBirth!.toDisplay()} (${member.age} years)',
            ),
          ],
          const Divider(height: AppSpacing.s32),
          _DetailRow(
            icon: PhosphorIcons.scales(),
            label: 'Weight',
            value: member.currentWeight != null
                ? '${member.currentWeight!.toStringAsFixed(1)} kg'
                : '—',
          ),
          if (member.heightCm != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.arrowsVertical(),
              label: 'Height',
              value: member.heightDisplay,
            ),
          ],
          if (member.bmi != null) ...[
            const Divider(height: AppSpacing.s32),
            _BmiRow(bmi: member.bmi!, category: member.bmiCategory!),
          ],
          if (member.bloodGroup != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.drop(),
              label: 'Blood Group',
              value: member.bloodGroup!,
            ),
          ],
          if (member.religion != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.book(),
              label: 'Religion',
              value: member.religion!,
            ),
          ],
          if (member.occupation != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.briefcase(),
              label: 'Occupation',
              value: member.occupation!,
            ),
          ],
          if (member.nid != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.identificationCard(),
              label: 'NID',
              value: member.nid!,
            ),
          ],
          if (member.emergencyPhone != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.phoneCall(),
              label: 'Emergency Phone',
              value: member.emergencyPhone!,
            ),
          ],
          if (member.presentAddress != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.mapPin(),
              label: 'Present Address',
              value: member.presentAddress!,
            ),
          ],
          if (member.permanentAddress != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.house(),
              label: 'Permanent Address',
              value: member.permanentAddress!,
            ),
          ],
          if (member.goal != null) ...[
            const Divider(height: AppSpacing.s32),
            _DetailRow(
              icon: PhosphorIcons.target(),
              label: 'Goal',
              value: member.goal!,
            ),
          ],
          if (member.hobbies.isNotEmpty) ...[
            const Divider(height: AppSpacing.s32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.r8,
                  ),
                  child: Icon(PhosphorIcons.star(),
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hobbies', style: AppText.labelSmall),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: member.hobbies
                            .map((h) => Chip(
                                  label: Text(h, style: AppText.labelSmall),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionsTab extends ConsumerWidget {
  const _SubscriptionsTab({required this.memberId, required this.screenId});
  final String memberId;
  final String screenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<MemberSubscription>>(
      future: ref.read(memberRepositoryProvider).getSubscriptions(memberId).then(
            (r) => r.data ?? [],
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SingleChildScrollView(
            padding: AppSpacing.paddingAll16,
            child: Column(
              children: [
                GymShimmer.card(height: 120),
                SizedBox(height: AppSpacing.s12),
                GymShimmer.card(height: 120),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return GymErrorState(message: snapshot.error.toString());
        }

        final subs = snapshot.data ?? [];

        if (subs.isEmpty) {
          return const Center(
            child: Text('No subscription history'),
          );
        }

        return ListView.separated(
          padding: AppSpacing.paddingAll16,
          itemCount: subs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
          itemBuilder: (context, index) {
            final sub = subs[index];
            return _SubHistoryCard(
              sub: sub,
              isFirst: index == 0,
              onEdit: sub.status == 'active'
                  ? () => GymBottomSheet.show<bool?>(
                        context: context,
                        title: 'Update Subscription',
                        child: UpdateSubscriptionSheet(
                          memberId: memberId,
                          subscription: sub,
                        ),
                      ).then((ok) {
                        if (ok == true) {
                          ref
                              .read(memberDetailControllerProvider(screenId)
                                  .notifier)
                              .load();
                        }
                      })
                  : null,
            );
          },
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({required this.memberId});
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: Future(() async {
        // Uses the ProviderContainer inside the widget tree via context.
        // We directly call the repository via a simple Future here.
        return [];
      }),
      builder: (context, _) => _MemberPaymentsList(memberId: memberId),
    );
  }
}

class _MemberPaymentsList extends ConsumerWidget {
  const _MemberPaymentsList({required this.memberId});
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Payment>>(
      future: ref
          .read(paymentRepositoryProvider)
          .list(memberId: memberId)
          .then((r) => r.data ?? []),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SingleChildScrollView(
            padding: AppSpacing.paddingAll16,
            child: Column(children: [
              GymShimmer.card(height: 72),
              SizedBox(height: AppSpacing.s8),
              GymShimmer.card(height: 72),
              SizedBox(height: AppSpacing.s8),
              GymShimmer.card(height: 72),
            ]),
          );
        }
        if (snapshot.hasError) {
          return GymErrorState(message: snapshot.error.toString());
        }
        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return const Center(child: Text('No payments recorded'));
        }
        return ListView.separated(
          padding: AppSpacing.paddingAll16,
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s8),
          itemBuilder: (context, i) => _PaymentRow(payment: payments[i]),
        );
      },
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingAll16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.r12,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.method, style: AppText.titleSmall),
                Text(payment.paidAt.toDisplay(),
                    style:
                        AppText.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            payment.amount.toBDT(),
            style: AppText.titleSmall.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SubHistoryCard extends StatelessWidget {
  const _SubHistoryCard({
    required this.sub,
    required this.isFirst,
    this.onEdit,
  });
  final MemberSubscription sub;
  final bool isFirst;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isActive = sub.status == 'active';
    return Container(
      padding: AppSpacing.paddingAll16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.r16,
        border: isActive
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sub.startDate.toDisplay()} – ${sub.endDate.toDisplay()}',
                style: AppText.titleSmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: AppSpacing.rFull,
                ),
                child: Text(
                  sub.status.toUpperCase(),
                  style: AppText.labelSmall.copyWith(
                    color: isActive ? AppColors.success : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sub.finalPrice.toBDT(),
                style: AppText.mono.copyWith(
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              if (sub.note != null && sub.note!.isNotEmpty)
                Expanded(
                  child: Text(
                    sub.note!,
                    textAlign: TextAlign.end,
                    style: AppText.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (onEdit != null) ...[
                const SizedBox(width: AppSpacing.s8),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.r8,
                    ),
                    child: Text('Edit',
                        style: AppText.labelSmall
                            .copyWith(color: AppColors.primary)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.memberId,
    required this.subscription,
    this.onEdit,
  });

  final String memberId;
  final MemberSubscription subscription;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final total = subscription.finalPrice;
    final paid = subscription.moneyPaid;
    final due = subscription.moneyLeft;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final isFullyPaid = due <= 0;

    final planLabel = subscription.planName.isNotEmpty
        ? subscription.planName
        : (subscription.note ?? 'Membership Plan');

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAll24,
      decoration: BoxDecoration(
        gradient: isFullyPaid ? AppColors.gradientGreen : AppColors.gradientOrange,
        borderRadius: AppSpacing.r24,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  planLabel,
                  style: AppText.labelSmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(PhosphorIcons.money(), color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            isFullyPaid 
                ? 'Fully Paid' 
                : (paid > 0 ? 'Partial Payment Done' : 'Payment Due'),
            style: AppText.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.s20),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            borderRadius: AppSpacing.rFull,
            minHeight: 10,
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CardAmount(label: 'Total', amount: total),
              _CardAmount(label: 'Paid', amount: paid),
              _CardAmount(label: 'Due', amount: due < 0 ? 0 : due),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          const Divider(color: Colors.white24),
          const SizedBox(height: AppSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${subscription.startDate.toDisplay()} – ${subscription.endDate.toDisplay()}',
                style: AppText.bodySmall.copyWith(color: Colors.white70),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.rFull,
                    ),
                    child: Text('Edit Plan', style: AppText.labelSmall.copyWith(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardAmount extends StatelessWidget {
  const _CardAmount({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.labelSmall.copyWith(color: Colors.white70)),
        const SizedBox(height: 2),
        Text(amount.toBDT(), style: AppText.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _BmiRow extends StatelessWidget {
  const _BmiRow({required this.bmi, required this.category});
  final double bmi;
  final String category;

  Color get _color => switch (category) {
        'Normal' => AppColors.success,
        'Underweight' => AppColors.info,
        'Overweight' => AppColors.warning,
        _ => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: AppSpacing.r8,
          ),
          child: Icon(PhosphorIcons.heartbeat(), color: _color, size: 20),
        ),
        const SizedBox(width: AppSpacing.s16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BMI', style: AppText.labelSmall),
            Row(
              children: [
                Text('${bmi.toStringAsFixed(1)}',
                    style: AppText.titleMedium),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.rFull,
                  ),
                  child: Text(category,
                      style: AppText.labelSmall.copyWith(color: _color)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.r8,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.s16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.labelSmall),
            Text(value, style: AppText.titleMedium),
          ],
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingAll24,
      child: Column(
        children: const [
          GymShimmer.avatar(size: 90),
          SizedBox(height: AppSpacing.s16),
          GymShimmer.line(width: 150, height: 24),
          SizedBox(height: AppSpacing.s8),
          GymShimmer.line(width: 100),
          SizedBox(height: AppSpacing.s32),
          GymShimmer.card(height: 200),
          SizedBox(height: AppSpacing.s24),
          GymShimmer.card(height: 48),
          SizedBox(height: AppSpacing.s12),
          GymShimmer.card(height: 48),
        ],
      ),
    );
  }
}

class _AiNutritionCard extends ConsumerStatefulWidget {
  const _AiNutritionCard({required this.member, required this.screenId});
  final Member member;
  final String screenId;

  @override
  ConsumerState<_AiNutritionCard> createState() => _AiNutritionCardState();
}

class _AiNutritionCardState extends ConsumerState<_AiNutritionCard> {
  bool _isUpdatingAI = false;
  bool _isGeneratingDiet = false;
  bool _isApprovingDeclining = false;
  String _dietLanguage = 'bn';
  final _gymTimeCtrl   = TextEditingController();
  final _locationCtrl  = TextEditingController();
  final _budgetCtrl    = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final isAiAllowed = member.isAiAllowed;
    final isAiFoodLogAllowed = member.isAiFoodLogAllowed;
    final budgetLevel = member.budgetLevel ?? 'Medium';
    final isAnyAiActive = isAiAllowed || isAiFoodLogAllowed;

    return GymCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.sparkle(), color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'AI & Nutrition Management',
                  style: AppText.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isAnyAiActive
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: AppSpacing.rFull,
                ),
                child: Text(
                  isAnyAiActive ? 'AI ACTIVE' : 'AI INACTIVE',
                  style: AppText.labelSmall.copyWith(
                    color: isAnyAiActive ? AppColors.primary : AppColors.textHint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          const Divider(),
          const SizedBox(height: AppSpacing.s12),
          // AI Diet features Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enable AI Diet Features', style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      'Allows AI diet planning & personalized recommendations',
                      style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              _isUpdatingAI
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Switch.adaptive(
                      value: isAiAllowed,
                      activeColor: AppColors.primary,
                      onChanged: (value) async {
                        setState(() => _isUpdatingAI = true);
                        try {
                          await ref.read(memberRepositoryProvider).updateAiSettings(
                                member.id,
                                isAiAllowed: value,
                                isAiFoodLogAllowed: isAiFoodLogAllowed,
                                budgetLevel: budgetLevel,
                              );
                          ref.read(memberDetailControllerProvider(widget.screenId).notifier).load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('AI Diet features updated successfully!')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update AI Diet features: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isUpdatingAI = false);
                        }
                      },
                    ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          // AI Food Log Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enable AI Photo Uploads', style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      'Allows photo-based food nutrition logging & tracking',
                      style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              _isUpdatingAI
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Switch.adaptive(
                      value: isAiFoodLogAllowed,
                      activeColor: AppColors.primary,
                      onChanged: (value) async {
                        setState(() => _isUpdatingAI = true);
                        try {
                          await ref.read(memberRepositoryProvider).updateAiSettings(
                                member.id,
                                isAiAllowed: isAiAllowed,
                                isAiFoodLogAllowed: value,
                                budgetLevel: budgetLevel,
                              );
                          ref.read(memberDetailControllerProvider(widget.screenId).notifier).load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('AI Photo Upload features updated successfully!')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update AI Photo Upload features: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isUpdatingAI = false);
                        }
                      },
                    ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          // Diet Budget Level Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diet Budget Level', style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      'AI will suggest meals matching this tier',
                      style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  value: ['Low', 'Medium', 'High'].contains(budgetLevel) ? budgetLevel : 'Medium',
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: _isUpdatingAI
                      ? null
                      : (val) async {
                          if (val == null) return;
                          setState(() => _isUpdatingAI = true);
                          try {
                            await ref.read(memberRepositoryProvider).updateAiSettings(
                                  member.id,
                                  isAiAllowed: isAiAllowed,
                                  isAiFoodLogAllowed: isAiFoodLogAllowed,
                                  budgetLevel: val,
                                );
                            ref.read(memberDetailControllerProvider(widget.screenId).notifier).load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Budget level set to $val')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update budget: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isUpdatingAI = false);
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          // Language toggle
          Row(
            children: [
              Text('Language:', style: AppText.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.s8),
              GestureDetector(
                onTap: () => setState(() => _dietLanguage = 'en'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _dietLanguage == 'en' ? AppColors.primary : Colors.grey.shade200,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                  child: Text(
                    'English',
                    style: AppText.bodySmall.copyWith(
                      color: _dietLanguage == 'en' ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _dietLanguage = 'bn'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _dietLanguage == 'bn' ? AppColors.primary : Colors.grey.shade200,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                  ),
                  child: Text(
                    'বাংলা',
                    style: AppText.bodySmall.copyWith(
                      color: _dietLanguage == 'bn' ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          // Diet inputs
          _DietInputField(controller: _gymTimeCtrl,  label: 'জিম টাইম', hint: 'যেমন: সন্ধ্যা ৬:০০ – ৭:৩০'),
          const SizedBox(height: AppSpacing.s8),
          _DietInputField(controller: _locationCtrl, label: 'লোকেশন',   hint: 'যেমন: বাগেরহাট'),
          const SizedBox(height: AppSpacing.s8),
          _DietInputField(controller: _budgetCtrl,   label: 'সর্বোচ্চ বাজেট (BDT)', hint: 'যেমন: ২০০', isNumber: true),
          const SizedBox(height: AppSpacing.s12),
          // Generate Plan Button
          SizedBox(
            width: double.infinity,
            child: _isGeneratingDiet
                ? Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.r12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Text(
                          'Generating Personalized AI Plan...',
                          style: AppText.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : GymButton.primary(
                    label: member.dietChart != null ? 'Re-Generate AI Diet Plan' : 'Generate AI Diet Plan',
                    icon: Icon(PhosphorIcons.magicWand(), color: Colors.white),
                    onPressed: () async {
                      setState(() => _isGeneratingDiet = true);
                      try {
                        await ref.read(memberRepositoryProvider).generateDietChart(
                          member.id,
                          language: _dietLanguage,
                          gymTime: _gymTimeCtrl.text.trim(),
                          location: _locationCtrl.text.trim(),
                          maxBudgetBdt: _budgetCtrl.text.trim(),
                        );
                        ref.read(memberDetailControllerProvider(widget.screenId).notifier).load();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI Diet Plan generated successfully!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to generate diet plan: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isGeneratingDiet = false);
                      }
                    },
                  ),
          ),
          if (member.dietChart != null) ...[
            const SizedBox(height: AppSpacing.s16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: AppSpacing.r8,
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This member has an active AI Diet Chart.',
                      style: AppText.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (member.pendingDietChart != null) ...[
            const SizedBox(height: AppSpacing.s24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50.withValues(alpha: 0.8),
                borderRadius: AppSpacing.r16,
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade200.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill), color: Colors.amber.shade800, size: 24),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          'Pending AI Diet Plan (Review Required)',
                          style: AppText.titleSmall.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'An AI-generated nutrition plan is awaiting your review. Please verify the meal details, times, and nutritional values before making it active for the member.',
                    style: AppText.bodySmall.copyWith(color: Colors.amber.shade900, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  // Meal schedule list preview
                  _PendingDietPreview(chart: member.pendingDietChart!),
                  const SizedBox(height: AppSpacing.s16),
                  Row(
                    children: [
                      Expanded(
                        child: _isApprovingDeclining
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success))
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.r12),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18),
                                label: const Text('Approve & Assign', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  setState(() => _isApprovingDeclining = true);
                                  try {
                                    await ref.read(memberRepositoryProvider).approveDietChart(member.id);
                                    ref.read(memberDetailControllerProvider(widget.screenId).notifier).load();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('AI Diet Plan approved & assigned successfully!')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to approve diet plan: $e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isApprovingDeclining = false);
                                  }
                                },
                              ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: _isApprovingDeclining
                            ? const SizedBox.shrink()
                            : OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.r12),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 18),
                                label: const Text('Decline Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Decline AI Plan?'),
                                      content: const Text('Are you sure you want to discard this pending AI Diet Plan? This action cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () => Navigator.of(context).pop(false),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                          child: const Text('Discard'),
                                          onPressed: () => Navigator.of(context).pop(true),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;

                                  setState(() => _isApprovingDeclining = true);
                                  try {
                                    await ref.read(memberRepositoryProvider).declineDietChart(member.id);
                                    ref.read(memberDetailControllerProvider(widget.screenId).notifier).load();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Pending AI Diet Plan discarded.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to discard diet plan: $e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isApprovingDeclining = false);
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingDietPreview extends StatelessWidget {
  const _PendingDietPreview({required this.chart});
  final Map<String, dynamic> chart;

  @override
  Widget build(BuildContext context) {
    final dailyCalories = chart['daily_calories'] ?? 2000;
    final macros = chart['macros'] as Map<String, dynamic>? ?? {};
    final protein = macros['protein'] ?? 150;
    final carbs = macros['carbs'] ?? 200;
    final fats = macros['fats'] ?? 65;

    final rawMeals = chart['meals'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> meals = rawMeals
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.r12,
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calories: $dailyCalories kcal',
            style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Protein: ${protein}g  ·  Carbs: ${carbs}g  ·  Fats: ${fats}g',
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 16),
          if (meals.isEmpty)
            Text('No meals generated in this plan.', style: AppText.bodySmall.copyWith(color: AppColors.textSecondary))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              separatorBuilder: (context, index) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final meal = meals[index];
                final String mealName = meal['name']?.toString() ?? 'Meal';
                final String mealTime = meal['time']?.toString() ?? '08:30 AM';
                final mealCal = meal['calories'] ?? 400;
                final List<dynamic> items = (meal['items'] as List<dynamic>?) ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      mealTime,
                                      style: AppText.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s8),
                                  Flexible(
                                    child: Text(
                                      mealName,
                                      style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$mealCal kcal',
                          style: AppText.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 4, top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: AppText.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                            Expanded(
                              child: Text(
                                item.toString(),
                                style: AppText.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Reusable diet input field ─────────────────────────────────────────────────

class _DietInputField extends StatelessWidget {
  const _DietInputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isNumber = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.bodySmall.copyWith(color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: AppText.bodySmall,
        ),
      ],
    );
  }
}
