import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/member/messages/chat_controller.dart';
import 'package:fitness_care_bagerhat/features/member/messages/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MemberMessagesScreen extends ConsumerStatefulWidget {
  const MemberMessagesScreen({super.key});

  @override
  ConsumerState<MemberMessagesScreen> createState() => _MemberMessagesScreenState();
}

class _MemberMessagesScreenState extends ConsumerState<MemberMessagesScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gym Support'),
            Text(
              'Admin • usually replies in 1 hr',
              style: AppText.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.phone()),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.when(
              loading: () => const _LoadingState(),
              error: (error, _) => GymErrorState(
                message: error.toString(),
                onRetry: () => ref.read(chatControllerProvider.notifier).load(),
              ),
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: AppSpacing.paddingAll20,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatBubble(
                      message: message,
                      isMe: message.senderRole == 'member',
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _messageController,
            onSend: () {
              if (_messageController.text.trim().isEmpty) return;
              ref.read(chatControllerProvider.notifier).send(_messageController.text.trim());
              _messageController.clear();
            },
          ),
        ],
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
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s8,
        AppSpacing.s8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(PhosphorIcons.paperclip(), color: AppColors.textSecondary),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill)),
            color: AppColors.primary,
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.paddingAll20,
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s16),
        child: Row(
          mainAxisAlignment: index.isEven ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            GymShimmer.card(
              height: 60,
              width: MediaQuery.of(context).size.width * 0.6,
            ),
          ],
        ),
      ),
    );
  }
}
