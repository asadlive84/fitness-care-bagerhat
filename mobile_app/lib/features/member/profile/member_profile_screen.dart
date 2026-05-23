import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_avatar.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:fitness_care_bagerhat/core/settings/settings_repository.dart';
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
              imageUrl: member?.profilePictureUrl != null && member!.profilePictureUrl!.isNotEmpty
                  ? (member.profilePictureUrl!.startsWith('http')
                      ? member.profilePictureUrl
                      : '${ref.read(settingsRepositoryProvider).baseUrl}${member.profilePictureUrl}')
                  : null,
            ),
            const SizedBox(height: AppSpacing.s32),

            if (member != null) ...[
              _Section(
                title: 'Member Info',
                children: [
                  _DetailRow(
                    label: 'Member Since',
                    value: member.joinDate?.toDisplay() ?? '—',
                    icon: PhosphorIcons.calendar(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Weight',
                    value: member.currentWeight != null
                        ? '${member.currentWeight!.toStringAsFixed(1)} kg'
                        : '—',
                    icon: PhosphorIcons.scales(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Height',
                    value: member.heightDisplay,
                    icon: PhosphorIcons.arrowsVertical(),
                  ),
                  if (member.bmi != null) ...[
                    const Divider(height: AppSpacing.s32),
                    _BmiRow(bmi: member.bmi!, category: member.bmiCategory!),
                  ],
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Phone Number',
                    value: member.phone,
                    icon: PhosphorIcons.phone(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Gender',
                    value: member.gender ?? '—',
                    icon: PhosphorIcons.genderIntersex(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Blood Group',
                    value: member.bloodGroup ?? '—',
                    icon: PhosphorIcons.drop(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Religion',
                    value: member.religion ?? '—',
                    icon: PhosphorIcons.book(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Date of Birth',
                    value: member.dateOfBirth != null
                        ? '${member.dateOfBirth!.toDisplay()} (${member.age} years)'
                        : '—',
                    icon: PhosphorIcons.cake(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Occupation',
                    value: member.occupation ?? '—',
                    icon: PhosphorIcons.briefcase(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'NID',
                    value: member.nid ?? '—',
                    icon: PhosphorIcons.identificationCard(),
                  ),
                  const Divider(height: AppSpacing.s32),
                  _DetailRow(
                    label: 'Emergency Phone',
                    value: member.emergencyPhone ?? '—',
                    icon: PhosphorIcons.phoneCall(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              
              if (member.presentAddress != null || member.permanentAddress != null) ...[
                _Section(
                  title: 'Addresses',
                  children: [
                    if (member.presentAddress != null) ...[
                      _DetailRow(
                        label: 'Present Address',
                        value: member.presentAddress!,
                        icon: PhosphorIcons.mapPin(),
                      ),
                      if (member.permanentAddress != null)
                        const Divider(height: AppSpacing.s32),
                    ],
                    if (member.permanentAddress != null)
                      _DetailRow(
                        label: 'Permanent Address',
                        value: member.permanentAddress!,
                        icon: PhosphorIcons.house(),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s20),
              ],

              if (member.goal != null || member.hobbies.isNotEmpty) ...[
                _Section(
                  title: 'Goals & Hobbies',
                  children: [
                    if (member.goal != null) ...[
                      _DetailRow(
                        label: 'Fitness Goal',
                        value: member.goal!,
                        icon: PhosphorIcons.target(),
                      ),
                      if (member.hobbies.isNotEmpty)
                        const Divider(height: AppSpacing.s32),
                    ],
                    if (member.hobbies.isNotEmpty)
                      _DetailRow(
                        label: 'Hobbies',
                        value: member.hobbies.join(', '),
                        icon: PhosphorIcons.star(),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s20),
              ],
            ],

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
                _Tile(
                  label: 'Developer Info',
                  icon: PhosphorIcons.code(),
                  onTap: () => context.push(Routes.developer),
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
    this.imageUrl,
  });

  final String name;
  final double? currentWeight;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GymAvatar(name: name, size: 80, imageUrl: imageUrl),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.r8,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.labelSmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppText.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _BmiRow extends StatelessWidget {
  const _BmiRow({required this.bmi, required this.category});
  final double bmi;
  final String category;

  Color get _color {
    if (category == 'Underweight') return AppColors.warning;
    if (category == 'Normal') return AppColors.success;
    if (category == 'Overweight') return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: AppSpacing.r8,
          ),
          child: Icon(PhosphorIcons.heartbeat(), color: _color, size: 20),
        ),
        const SizedBox(width: AppSpacing.s16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BMI', style: AppText.labelSmall.copyWith(color: AppColors.textSecondary)),
            Row(
              children: [
                Text(bmi.toStringAsFixed(1), style: AppText.titleSmall),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.rFull,
                  ),
                  child: Text(
                    category,
                    style: AppText.labelSmall.copyWith(color: _color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
