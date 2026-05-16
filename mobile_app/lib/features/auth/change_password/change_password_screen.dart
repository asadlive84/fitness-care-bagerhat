import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_repository.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ## ChangePasswordScreen
///
/// Two flows:
/// - **Forced** — `must_change_password == true` after login with a temp
///   password.  No back button; navigates to role home on success.
/// - **Voluntary** — reached from admin Settings or member Profile.
///   Back button shown; pops with a success snackbar on completion.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool get _isForced =>
      ref.read(authProvider).value?.status == AuthStatus.mustChangePassword;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );

      if (_isForced) {
        // Forced: mark done, then go to role home.
        ref.read(authProvider.notifier).markPasswordChanged();
        final role = ref.read(authProvider).value?.role;
        if (context.mounted) {
          context.go(role == 'admin' ? Routes.adminDashboard : Routes.memberHome);
        }
      } else {
        // Voluntary: pop back with a success message.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final forced = _isForced;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        automaticallyImplyLeading: !forced, // no back in forced flow
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll24,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (forced) ...[
                Container(
                  padding: AppSpacing.paddingAll16,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.r12,
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.warningCircle(),
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Text(
                          'You are using a temporary password. '
                          'Set a permanent password to continue.',
                          style: AppText.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
              ],

              Text(
                forced ? 'Secure your account' : 'Update your password',
                style: AppText.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                forced
                    ? 'Enter the temporary password you received, then choose a new one.'
                    : 'Enter your current password, then choose a new one.',
                style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s32),

              GymTextField(
                label: forced ? 'Temporary Password' : 'Current Password',
                hint: '••••••••',
                controller: _currentController,
                obscureText: true,
                prefixIcon: Icon(PhosphorIcons.key()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.s20),

              GymTextField(
                label: 'New Password',
                hint: '••••••••',
                controller: _newController,
                obscureText: true,
                prefixIcon: Icon(PhosphorIcons.lock()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s20),

              GymTextField(
                label: 'Confirm New Password',
                hint: '••••••••',
                controller: _confirmController,
                obscureText: true,
                prefixIcon: Icon(PhosphorIcons.lockKey()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _newController.text) return 'Passwords do not match';
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s16),
                Container(
                  padding: AppSpacing.paddingAll12,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.r8,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppText.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
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
      ),
    );
  }
}
