import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/member_detail_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/members/widgets/member_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditMemberScreen extends ConsumerStatefulWidget {
  const EditMemberScreen({
    required this.id,
    required this.member,
    super.key,
  });

  final String id;
  final Member member;

  @override
  ConsumerState<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends ConsumerState<EditMemberScreen> {
  bool _isLoading = false;

  Future<void> _onSubmit(MemberFormData data) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(memberRepositoryProvider).update(widget.id, {
        'name': data.name,
        'phone': data.phone,
        if (data.goal != null) 'goal': data.goal,
        if (data.currentWeight != null) 'current_weight': data.currentWeight,
        if (data.heightCm != null) 'height_cm': data.heightCm,
        if (data.dateOfBirth != null)
          'date_of_birth':
              data.dateOfBirth!.toIso8601String().split('T')[0],
        if (data.religion != null) 'religion': data.religion,
        if (data.bloodGroup != null) 'blood_group': data.bloodGroup,
        'hobbies': data.hobbies,
        if (data.presentAddress != null) 'present_address': data.presentAddress,
        if (data.permanentAddress != null)
          'permanent_address': data.permanentAddress,
        if (data.occupation != null) 'occupation': data.occupation,
        if (data.nid != null) 'nid': data.nid,
        if (data.emergencyPhone != null) 'emergency_phone': data.emergencyPhone,
      });

      ref.invalidate(memberDetailControllerProvider(widget.id));
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member updated successfully')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll20,
        child: Column(
          children: [
            MemberForm(
              member: widget.member,
              isLoading: _isLoading,
              onSubmit: _onSubmit,
            ),
            const SizedBox(height: AppSpacing.s32),
          ],
        ),
      ),
    );
  }
}
