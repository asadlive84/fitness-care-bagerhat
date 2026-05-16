import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:fitness_care_bagerhat/features/member/profile/member_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ## EditProfileScreen
///
/// Lets a member update their name, goal, and current weight.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({required this.member, super.key});

  final Member member;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _goalController;
  late final TextEditingController _weightController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _goalController = TextEditingController();
    _weightController = TextEditingController(
      text: widget.member.currentWeight?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(memberProfileRepositoryProvider).updateProfile(
            name: _nameController.text.trim(),
            goal: _goalController.text.trim().isEmpty
                ? null
                : _goalController.text.trim(),
            currentWeight: _weightController.text.trim().isEmpty
                ? null
                : double.tryParse(_weightController.text.trim()),
          );

      // Refresh the home screen state so it reflects new data
      await ref.read(memberHomeControllerProvider.notifier).load();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll24,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your profile information below.',
                style: AppText.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.s32),
              GymTextField(
                label: 'Full Name',
                hint: 'Your name',
                controller: _nameController,
                prefixIcon: Icon(PhosphorIcons.user()),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Name must be at least 2 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.s20),
              GymTextField(
                label: 'Goal (Optional)',
                hint: 'e.g. Weight loss, Muscle gain',
                controller: _goalController,
                prefixIcon: Icon(PhosphorIcons.target()),
              ),
              const SizedBox(height: AppSpacing.s20),
              GymTextField(
                label: 'Current Weight (kg)',
                hint: 'e.g. 72.5',
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(PhosphorIcons.scales()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0 || parsed > 500) {
                    return 'Enter a valid weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s40),
              GymButton.primary(
                label: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
