import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_repository.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ## ChangePasswordScreen
///
/// Forced screen if user is logging in with a temporary password.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    if (newPass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: current,
            newPassword: newPass,
          );
      ref.read(authProvider.notifier).markPasswordChanged();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Password'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure your account',
              style: AppText.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'You are using a temporary password. Please set a new one to continue.',
              style: AppText.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s32),
            GymTextField(
              label: 'Current Password',
              hint: '••••••••',
              controller: _currentPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.s20),
            GymTextField(
              label: 'New Password',
              hint: '••••••••',
              controller: _newPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.s20),
            GymTextField(
              label: 'Confirm New Password',
              hint: '••••••••',
              controller: _confirmPasswordController,
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s16),
              Text(
                _error!,
                style: AppText.labelSmall.copyWith(color: Colors.red),
              ),
            ],
            const SizedBox(height: AppSpacing.s40),
            GymButton.primary(
              label: 'Update Password',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
