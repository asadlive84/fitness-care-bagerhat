import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_avatar.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:fitness_care_bagerhat/features/member/notifications/notification_repository.dart';
import 'package:fitness_care_bagerhat/features/member/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ## MemberProfileScreen
///
/// Member self-service profile with navigation to subscription, payments,
/// edit profile, notification settings, and logout.
class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  bool _isMuted = false;
  bool _isTogglingMute = false;

  Future<void> _toggleMute() async {
    setState(() => _isTogglingMute = true);
    try {
      await ref.read(notificationRepositoryProvider).setMutePreference(
            muted: !_isMuted,
          );
      setState(() => _isMuted = !_isMuted);
    } catch (_) {
      // Silently fail — notification mute is non-critical
    } finally {
      if (mounted) setState(() => _isTogglingMute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).value;
    final homeState = ref.watch(memberHomeControllerProvider);
    final member = homeState.valueOrNull?.member;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (member != null)
            IconButton(
              icon: Icon(PhosphorIcons.pencilSimple()),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => EditProfileScreen(member: member),
                ),
              ).then((updated) {
                if (updated == true) {
                  ref.read(memberHomeControllerProvider.notifier).load();
                }
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll20,
        child: Column(
          children: [
            _Header(
              name: member?.name ?? authState?.userName ?? 'Member',
              currentWeight: member?.currentWeight,
            ),
            const SizedBox(height: AppSpacing.s32),

            _Section(
              title: 'Membership',
              children: [
                _Tile(
                  label: 'My Subscription',
                  icon: PhosphorIcons.crown(),
                  onTap: () => context.push(Routes.memberSubscription),
                ),
                _Tile(
                  label: 'Payment History',
                  icon: PhosphorIcons.receipt(),
                  onTap: () => context.push(Routes.memberPayments),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),

            _Section(
              title: 'Preferences',
              children: [
                _Tile(
                  label: 'Mute Notifications',
                  icon: _isMuted
                      ? PhosphorIcons.bellSlash()
                      : PhosphorIcons.bell(),
                  trailing: _isTogglingMute
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch.adaptive(
                          value: _isMuted,
                          onChanged: (_) => _toggleMute(),
                        ),
                ),
                _Tile(
                  label: 'Change Password',
                  icon: PhosphorIcons.key(),
                  onTap: () => context.push(Routes.changePassword),
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
              ],
            ),
            const SizedBox(height: AppSpacing.s40),

            GymButton.danger(
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child:
                const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    this.currentWeight,
  });

  final String name;
  final double? currentWeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GymAvatar(name: name, size: 80),
        const SizedBox(height: AppSpacing.s16),
        Text(name, style: AppText.titleLarge),
        if (currentWeight != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${currentWeight!.toStringAsFixed(1)} kg current weight',
            style: AppText.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
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
          child: Column(children: children),
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
