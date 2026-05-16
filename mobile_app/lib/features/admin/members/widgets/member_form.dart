import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MemberForm extends StatefulWidget {
  const MemberForm({
    super.key,
    this.member,
    required this.onSubmit,
    required this.isLoading,
  });

  final Member? member;
  final Function(String name, String phone, String? email) onSubmit;
  final bool isLoading;

  @override
  State<MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<MemberForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name);
    _phoneController = TextEditingController(text: widget.member?.phone);
    // Assuming email might be added to Member model later or handled separately
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          GymTextField(
            label: 'Full Name',
            hint: 'e.g. Karim Ahmed',
            controller: _nameController,
            prefixIcon: Icon(PhosphorIcons.user()),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter name';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s20),
          GymTextField(
            label: 'Phone Number',
            hint: '01711-XXXXXX',
            controller: _phoneController,
            prefixIcon: Icon(PhosphorIcons.phone()),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter phone';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s20),
          GymTextField(
            label: 'Email (Optional)',
            hint: 'member@example.com',
            controller: _emailController,
            prefixIcon: Icon(PhosphorIcons.envelope()),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.s40),
          GymButton.primary(
            label: widget.member == null ? 'Create Member' : 'Save Changes',
            isLoading: widget.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
