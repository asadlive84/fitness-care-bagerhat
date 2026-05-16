import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll16,
        child: Column(
          children: [
            // Profile Section
            _ProfileHeader(
              name: authState?.userName ?? 'Admin',
              role: authState?.role ?? 'Owner',
            ),
            const SizedBox(height: AppSpacing.s32),

            // Settings Groups
            _SettingsGroup(
              title: 'App Preferences',
              children: [
                _SettingsTile(
                  label: 'Dark Mode',
                  icon: PhosphorIcons.moon(),
                  trailing: Switch.adaptive(
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (val) {
                      // Implementation for theme toggle
                    },
                  ),
                ),
                _SettingsTile(
                  label: 'Language',
                  icon: PhosphorIcons.translate(),
                  value: 'English',
                  onTap: () {},
                ),
                _SettingsTile(
                  label: 'Notifications',
                  icon: PhosphorIcons.bell(),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),

            _SettingsGroup(
              title: 'Account & Security',
              children: [
                _SettingsTile(
                  label: 'Change Password',
                  icon: PhosphorIcons.lock(),
                  onTap: () {},
                ),
                _SettingsTile(
                  label: 'Privacy Policy',
                  icon: PhosphorIcons.shieldCheck(),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s40),

            // Logout Button
            GymButton.secondary(
              label: 'Logout',
              icon: Icon(PhosphorIcons.signOut()),
              onPressed: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Version 1.0.0 (Build 12)',
              style: AppText.labelSmall.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.role});
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingAll24,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppSpacing.r24,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 32, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.s20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.titleLarge.copyWith(color: Colors.white),
                ),
                Text(
                  role,
                  style: AppText.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppText.labelSmall),
        ),
        GymCard(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    required this.icon,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(label, style: AppText.bodyMedium),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                Text(
                  value!,
                  style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
            ],
          ),
    );
  }
}
