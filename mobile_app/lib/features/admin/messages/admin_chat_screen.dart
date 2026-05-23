import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/member_detail_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/message.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/message_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Provider for the conversation messages for a specific member.
final adminChatProvider = StateNotifierProvider.autoDispose
    .family<AdminChatController, AsyncValue<List<Message>>, String>(
  (ref, memberId) =>
      AdminChatController(memberId: memberId, repo: ref.watch(messageRepositoryProvider)),
);

class AdminChatController extends StateNotifier<AsyncValue<List<Message>>> {
  AdminChatController({required this.memberId, required this.repo})
      : super(const AsyncValue.loading()) {
    load();
  }

  final String memberId;
  final MessageRepository repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final response = await repo.getConversation(memberId);
      state = AsyncValue.data(response.data ?? []);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> send(String content) async {
    try {
      await repo.sendDirect(memberId: memberId, content: content);
      await load();
    } catch (_) {}
  }
}

/// ## AdminChatScreen
///
/// Full conversation view between admin and a specific member.
class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({
    required this.memberId,
    this.memberName,
    super.key,
  });

  final String memberId;
  final String? memberName;

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(adminChatProvider(widget.memberId).notifier).send(text);
    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminChatProvider(widget.memberId));
    final memberState = ref.watch(memberDetailControllerProvider(widget.memberId));
    final memberName = memberState.value?.name ?? widget.memberName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context.push(Routes.adminMemberDetail(widget.memberId)),
          child: memberState.isLoading && memberName.isEmpty
              ? const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(),
                )
              : Text(memberName),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.userCircle()),
            tooltip: 'View profile',
            onPressed: () => context.push(Routes.adminMemberDetail(widget.memberId)),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise()),
            onPressed: () =>
                ref.read(adminChatProvider(widget.memberId).notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.when(
              loading: () => ListView.builder(
                padding: AppSpacing.paddingAll16,
                itemCount: 6,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: Row(
                    mainAxisAlignment: i.isEven
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      GymShimmer.card(
                        height: 48,
                        width: MediaQuery.of(context).size.width * 0.6,
                      ),
                    ],
                  ),
                ),
              ),
              error: (e, _) => GymErrorState(
                message: e.toString(),
                onRetry: () =>
                    ref.read(adminChatProvider(widget.memberId).notifier).load(),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.chatTeardropDots(),
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        Text(
                          'No messages yet.',
                          style: AppText.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'Send the first message below.',
                          style: AppText.bodySmall
                              .copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(adminChatProvider(widget.memberId).notifier).load(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: AppSpacing.paddingAll16,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isAdmin = msg.senderRole == 'admin';
                      return _ChatBubble(message: msg, isAdmin: isAdmin);
                    },
                  ),
                );
              },
            ),
          ),
          _InputBar(
            controller: _controller,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isAdmin});
  final Message message;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSpacing.s8,
          left: isAdmin ? 60 : 0,
          right: isAdmin ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: isAdmin ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAdmin ? 16 : 4),
            bottomRight: Radius.circular(isAdmin ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppText.bodyMedium.copyWith(
                color: isAdmin ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.sentAt.toDisplayTime(),
                  style: AppText.labelSmall.copyWith(
                    color: isAdmin
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.readAt != null
                        ? Icons.done_all
                        : Icons.done,
                    size: 12,
                    color: message.readAt != null
                        ? Colors.lightBlueAccent
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppText.bodyMedium
                      .copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.r24,
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.bgLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
