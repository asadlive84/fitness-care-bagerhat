import 'dart:ui';

import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/auth/login/login_controller.dart';
import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ## LoginScreen
///
/// Premium login screen with role selection, frosted glass card,
/// and smooth animations.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final isAdmin = state.role == 'admin';

    return Scaffold(
      body: Stack(
        children: [
          // ─── Background Image with Overlay ──────────────────
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: AppColors.bgDark.withValues(alpha: 0.65),
            ),
          ),

          // ─── Content ───────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingAll24,
                child: Column(
                  children: [
                    // Logo Section
                    Hero(
                      tag: 'app_logo',
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              size: 48,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            'FITNESS CARE',
                            style: AppText.headlineLarge.copyWith(
                              color: AppColors.textOnDark,
                              letterSpacing: 4,
                            ),
                          ),
                          Text(
                            'BAGERHAT',
                            style: AppText.labelSmall.copyWith(
                              color: AppColors.primaryLight,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s48),

                    // Frosted Glass Login Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ClipRRect(
                          borderRadius: AppSpacing.r24,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: AppSpacing.paddingAll24,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: AppSpacing.r24,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome back 👋',
                                            style: AppText.titleLarge.copyWith(
                                              color: AppColors.textOnDark,
                                            ),
                                          ),
                                          Text(
                                            'Sign in to continue',
                                            style: AppText.bodyMedium.copyWith(
                                              color: AppColors.textHint,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.settings_input_component, color: AppColors.primaryLight),
                                        onPressed: () => _showServerSettings(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.s12),
                                  _ServerStatusIndicator(),
                                  const SizedBox(height: AppSpacing.s24),

                                  // Role Selector
                                  _RoleSelector(
                                    selectedRole: state.role,
                                    onChanged: (role) => ref
                                        .read(loginControllerProvider.notifier)
                                        .setRole(role),
                                  ),
                                  const SizedBox(height: AppSpacing.s24),

                                  // Form Fields
                                  GymTextField(
                                    label: isAdmin ? 'Email' : 'Phone',
                                    hint: isAdmin
                                        ? 'admin@example.com'
                                        : '01711-XXXXXX',
                                    controller: _identifierController,
                                    keyboardType: isAdmin
                                        ? TextInputType.emailAddress
                                        : TextInputType.phone,
                                  ),
                                  const SizedBox(height: AppSpacing.s16),
                                  GymTextField(
                                    label: 'Password',
                                    hint: '••••••••',
                                    controller: _passwordController,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                  ),

                                  if (state.error != null) ...[
                                    const SizedBox(height: AppSpacing.s12),
                                    Text(
                                      state.error!,
                                      style: AppText.labelSmall.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: AppSpacing.s32),

                                  // Login Button
                                  GymButton.primary(
                                    label: 'Sign In',
                                    isLoading: state.isLoading,
                                    onPressed: () => ref
                                        .read(loginControllerProvider.notifier)
                                        .login(
                                          _identifierController.text,
                                          _passwordController.text,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s32),
                    Text(
                      'v1.0.0',
                      style: AppText.labelSmall.copyWith(
                        color: AppColors.textHint.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showServerSettings(BuildContext context) {
    final settings = ref.read(settingsRepositoryProvider);
    final controller = TextEditingController(text: settings.baseUrl);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the backend API URL. For Android Emulators, use http://10.0.2.2:9000',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://10.0.2.2:9000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.setBaseUrl(controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API URL updated. Refreshing...')),
                );
                ref.invalidate(apiClientProvider);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: AppSpacing.rFull,
      ),
      child: Row(
        children: [
          _RoleButton(
            label: 'Member',
            isSelected: selectedRole == 'member',
            onTap: () => onChanged('member'),
          ),
          _RoleButton(
            label: 'Admin',
            isSelected: selectedRole == 'admin',
            onTap: () => onChanged('admin'),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: AppSpacing.rFull,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.labelLarge.copyWith(
              color: isSelected ? Colors.white : AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(settingsRepositoryProvider).baseUrl;
    
    return FutureBuilder(
      future: ref.read(apiClientProvider).get('/healthz'),
      builder: (context, snapshot) {
        final isConnected = snapshot.hasData && snapshot.data?.statusCode == 200;
        final isChecking = snapshot.connectionState == ConnectionState.waiting;

        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecking 
                  ? Colors.orange 
                  : (isConnected ? Colors.green : Colors.red),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isChecking 
                ? 'Checking connection...' 
                : (isConnected ? 'Server Connected' : 'Server Disconnected'),
              style: AppText.labelSmall.copyWith(
                color: isChecking 
                  ? Colors.orange 
                  : (isConnected ? Colors.green : Colors.red),
              ),
            ),
            const Spacer(),
            Text(
              baseUrl.replaceAll('http://', ''),
              style: AppText.labelSmall.copyWith(color: AppColors.textHint),
            ),
          ],
        );
      },
    );
  }
}
