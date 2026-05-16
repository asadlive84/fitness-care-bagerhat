import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll20,
        child: Column(
          children: [
            _Header(
              name: authState?.userName ?? 'Member',
              phone: '', // Phone not in AuthState, could add if needed
            ),
            const SizedBox(height: AppSpacing.s32),
            
            _Section(
              title: 'Membership',
              children: [
                _Tile(
                  label: 'My Subscription',
                  icon: PhosphorIcons.crown(),
                  onTap: () {},
                ),
                _Tile(
                  label: 'Payment History',
                  icon: PhosphorIcons.receipt(),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),

            _Section(
              title: 'Preferences',
              children: [
                _Tile(
                  label: 'Notification Settings',
                  icon: PhosphorIcons.bell(),
                  onTap: () {},
                ),
                _Tile(
                  label: 'Dark Mode',
                  icon: PhosphorIcons.moon(),
                  trailing: Switch.adaptive(
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (val) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),

            _Section(
              title: 'Support',
              children: [
                _Tile(
                  label: 'About Fitness Care',
                  icon: PhosphorIcons.info(),
                  onTap: () {},
                ),
                _Tile(
                  label: 'Privacy Policy',
                  icon: PhosphorIcons.shieldCheck(),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s40),

            GymButton.secondary(
              label: 'Logout',
              icon: Icon(PhosphorIcons.signOut()),
              onPressed: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: AppSpacing.s40),
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
        content: const Text('Are you sure you want to sign out?'),
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

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.phone});
  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(name, style: AppText.titleLarge),
        Text(
          phone,
          style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(label, style: AppText.bodyMedium),
      trailing: trailing ??
          Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
    );
  }
}
