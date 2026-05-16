import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
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

  Future<void> _onSubmit(MemberFormData data) async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(memberRepositoryProvider).create(
            name: data.name,
            phone: data.phone,
            goal: data.goal,
            currentWeight: data.currentWeight,
            heightCm: data.heightCm,
            joinDate: data.joinDate,
            dateOfBirth: data.dateOfBirth,
            religion: data.religion,
            bloodGroup: data.bloodGroup,
            hobbies: data.hobbies,
            presentAddress: data.presentAddress,
            permanentAddress: data.permanentAddress,
            occupation: data.occupation,
            nid: data.nid,
            emergencyPhone: data.emergencyPhone,
          );
      if (mounted) {
        _showSuccessDialog(data.name, result.tempPassword);
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Member Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temporary password for $name:'),
            const SizedBox(height: AppSpacing.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: AppSpacing.r8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tempPassword, style: AppText.mono),
                  const SizedBox(width: AppSpacing.s8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tempPassword));
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
              'Share this with the member. They must change it on their first login.',
              style: AppText.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
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
        padding: AppSpacing.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fill in the member details. A temporary password will be generated automatically.',
              style: AppText.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s24),
            MemberForm(isLoading: _isLoading, onSubmit: _onSubmit),
            const SizedBox(height: AppSpacing.s32),
          ],
        ),
      ),
    );
  }
}
