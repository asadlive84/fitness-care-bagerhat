import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/message_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/messages_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rxdart/rxdart.dart';

class ComposeMessageSheet extends ConsumerStatefulWidget {
  const ComposeMessageSheet({
    this.initialRecipient,
    this.isBulk = false,
    super.key,
  });

  final Member? initialRecipient;
  final bool isBulk;

  @override
  ConsumerState<ComposeMessageSheet> createState() => _ComposeMessageSheetState();
}

class _ComposeMessageSheetState extends ConsumerState<ComposeMessageSheet> {
  final _contentController = TextEditingController();
  final _searchSubject = PublishSubject<String>();
  List<Member> _searchResults = [];
  Member? _selectedMember;
  String _selectedType = 'sms';
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialRecipient;
    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen(_performSearch);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final response = await ref.read(memberRepositoryProvider).list(search: query);
      setState(() => _searchResults = response.data ?? []);
    } catch (_) {
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.isEmpty) return;
    if (!widget.isBulk && _selectedMember == null) return;

    setState(() => _isLoading = true);
    try {
      if (widget.isBulk) {
        await ref.read(messageRepositoryProvider).sendBroadcast(
              content: _contentController.text.trim(),
            );
      } else {
        await ref.read(messageRepositoryProvider).sendDirect(
              memberId: _selectedMember!.id,
              content: _contentController.text.trim(),
            );
      }
      
      await ref.read(messagesControllerProvider.notifier).load(refresh: true);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isBulk)
          Container(
            padding: AppSpacing.paddingAll12,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: AppSpacing.r12,
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.users(), color: AppColors.accent),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  'This message will be sent to ALL members.',
                  style: AppText.labelMedium,
                ),
              ],
            ),
          )
        else ...[
          Text('Recipient', style: AppText.labelSmall),
          const SizedBox(height: AppSpacing.s8),
          if (_selectedMember != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_selectedMember!.name),
              subtitle: Text(_selectedMember!.phone),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedMember = null),
              ),
            )
          else
            Column(
              children: [
                GymTextField(
                  hint: 'Search member by name or phone...',
                  onChanged: (val) => _searchSubject.add(val),
                  prefixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(PhosphorIcons.magnifyingGlass()),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.r12,
                      border: Border.all(color: AppColors.divider),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final member = _searchResults[index];
                        return ListTile(
                          title: Text(member.name),
                          subtitle: Text(member.phone),
                          onTap: () => setState(() {
                            _selectedMember = member;
                            _searchResults = [];
                          }),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
        const SizedBox(height: AppSpacing.s24),
        Text('Notification Type', style: AppText.labelSmall),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            _TypeButton(
              label: 'SMS',
              icon: PhosphorIcons.chatText(),
              isSelected: _selectedType == 'sms',
              onTap: () => setState(() => _selectedType = 'sms'),
            ),
            const SizedBox(width: AppSpacing.s12),
            _TypeButton(
              label: 'Push',
              icon: PhosphorIcons.bell(),
              isSelected: _selectedType == 'push',
              onTap: () => setState(() => _selectedType = 'push'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        GymTextField(
          label: 'Message Content',
          hint: 'Write your message here...',
          controller: _contentController,
          maxLines: 4,
          onChanged: (val) => setState(() {}),
        ),
        if (_selectedType == 'sms')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Characters: ${_contentController.text.length} · Approx ${_contentController.text.isEmpty ? 0 : (_contentController.text.length / 160).ceil()} SMS',
              style: AppText.labelSmall.copyWith(color: AppColors.textHint),
            ),
          ),
        const SizedBox(height: AppSpacing.s40),
        GymButton.primary(
          label: widget.isBulk ? 'Send to All' : 'Send Message',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: AppSpacing.r12,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppText.labelLarge.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
