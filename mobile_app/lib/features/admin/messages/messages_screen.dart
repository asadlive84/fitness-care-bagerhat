import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_bottom_sheet.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/messages_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/widgets/compose_message_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.paperPlaneTilt()),
            onPressed: () => _showCompose(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickActions(context),
          const Divider(height: 1),
          Expanded(
            child: _buildHistoryList(state, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingAll16,
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              label: 'Single Member',
              icon: PhosphorIcons.user(),
              color: AppColors.primary,
              onTap: () => _showCompose(context, isBulk: false),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: _QuickActionCard(
              label: 'Bulk Message',
              icon: PhosphorIcons.users(),
              color: AppColors.accent,
              onTap: () => _showCompose(context, isBulk: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(MessagesState state, WidgetRef ref) {
    if (state.isLoading) {
      return ListView.separated(
        padding: AppSpacing.paddingAll16,
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, __) => const GymShimmer.line(height: 60),
      );
    }

    if (state.error != null) {
      return GymErrorState(
        message: state.error!.message,
        onRetry: () =>
            ref.read(messagesControllerProvider.notifier).load(refresh: true),
      );
    }

    if (state.conversations.isEmpty) {
      return const GymEmptyState(
        message: 'No messages sent yet.',
        animationPath: 'assets/animations/empty_messages.json',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(messagesControllerProvider.notifier).load(refresh: true),
      child: ListView.separated(
        padding: AppSpacing.paddingAll16,
        itemCount: state.conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (context, index) {
          final conv = state.conversations[index];
          final isUnread = conv.senderRole == 'member';
          final displayName = (conv.memberName != null && conv.memberName!.isNotEmpty)
              ? conv.memberName!
              : 'Member …${conv.memberId.substring(conv.memberId.length - 6)}';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => context.push(
              Routes.adminChat(conv.memberId),
              extra: conv.memberName,
            ),
            leading: GestureDetector(
              onTap: () => context.push(Routes.adminMemberDetail(conv.memberId)),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(PhosphorIcons.user(), color: AppColors.primary, size: 20),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(Routes.adminMemberDetail(conv.memberId)),
                    child: Text(
                      displayName,
                      style: AppText.titleSmall.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              conv.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySmall.copyWith(
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Text(
              conv.lastSentAt.toRelative(),
              style: AppText.labelSmall.copyWith(color: AppColors.textHint),
            ),
          );
        },
      ),
    );
  }

  void _showCompose(BuildContext context, {bool isBulk = false}) {
    GymBottomSheet.show<void>(
      context: context,
      title: isBulk ? 'Bulk Message' : 'Send Message',
      child: ComposeMessageSheet(isBulk: isBulk),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingAll16,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppSpacing.r16,
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.s8),
            Text(
              label,
              style: AppText.labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
