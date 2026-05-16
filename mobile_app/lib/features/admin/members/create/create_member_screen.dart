import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/members/widgets/member_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateMemberScreen extends ConsumerStatefulWidget {
  const CreateMemberScreen({super.key});

  @override
  ConsumerState<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends ConsumerState<CreateMemberScreen> {
  bool _isLoading = false;

  Future<void> _onSubmit(String name, String phone, String? email) async {
    setState(() => _isLoading = true);
    try {
      final member = await ref.read(memberRepositoryProvider).create(
            name: name,
            phone: phone,
          );
      if (mounted) {
        // Show success dialog with temp password (simulated since backend returns it)
        _showSuccessDialog(name, '123456'); // Backend should return this
      }
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

  void _showSuccessDialog(String name, String tempPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Member Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temporary password for $name:'),
            const SizedBox(height: AppSpacing.s12),
            Container(
              padding: EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: AppSpacing.r8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tempPassword,
                    style: AppText.mono.copyWith(fontSize: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tempPassword));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Please share this password with the member. They will be forced to change it on their first login.',
              style: AppText.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // Go back to list
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A temporary password will be generated for this member.',
              style: AppText.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s32),
            MemberForm(
              isLoading: _isLoading,
              onSubmit: _onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
