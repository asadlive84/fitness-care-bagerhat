import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/settings/admin_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final _settingsProvider =
    StateNotifierProvider.autoDispose<_SettingsController, AsyncValue<List<AppSetting>>>(
  (ref) => _SettingsController(ref.watch(adminSettingsRepositoryProvider)),
);

class _SettingsController extends StateNotifier<AsyncValue<List<AppSetting>>> {
  _SettingsController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final AdminSettingsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.getAll());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> upsert(String key, dynamic value) async {
    await _repo.upsert(key: key, value: value);
    await load();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

/// ## SettingsScreen
///
/// Admin settings — reads from and writes to the backend key-value store.
/// Includes gym-operation settings (reminder days, quiet window) plus
/// account/logout controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).value;
    final settingsState = ref.watch(_settingsProvider);

    // Build a helper lookup for the current settings values.
    final settingsMap = settingsState.whenOrNull(
          data: (list) => {for (final s in list) s.key: s},
        ) ??
        {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise()),
            onPressed: () => ref.read(_settingsProvider.notifier).load(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll16,
        child: Column(
          children: [
            // ── Admin profile header ──────────────────────────────
            _ProfileHeader(name: authState?.userName ?? 'Admin'),
            const SizedBox(height: AppSpacing.s32),

            // ── Gym operation settings (from backend) ─────────────
            _Section(
              title: 'Gym Operations',
              child: settingsState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    children: [
                      GymShimmer.line(height: 48),
                      SizedBox(height: AppSpacing.s12),
                      GymShimmer.line(height: 48),
                      SizedBox(height: AppSpacing.s12),
                      GymShimmer.line(height: 48),
                    ],
                  ),
                ),
                error: (e, _) => Padding(
                  padding: AppSpacing.paddingAll16,
                  child: Text(
                    'Could not load settings: $e',
                    style:
                        AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                data: (_) => Column(
                  children: [
                    _NumberSettingTile(
                      label: 'Expiry Reminder (days)',
                      subtitle:
                          'Notify members this many days before subscription ends.',
                      icon: PhosphorIcons.bellRinging(),
                      value: settingsMap['expiry_reminder_days']?.asInt(7) ?? 7,
                      onSave: (v) => ref
                          .read(_settingsProvider.notifier)
                          .upsert('expiry_reminder_days', v),
                    ),
                    const Divider(height: 1),
                    _NumberSettingTile(
                      label: 'Weight Reminder (days)',
                      subtitle:
                          'Remind members who haven\'t logged weight in this many days.',
                      icon: PhosphorIcons.scales(),
                      value:
                          settingsMap['weight_reminder_days']?.asInt(7) ?? 7,
                      onSave: (v) => ref
                          .read(_settingsProvider.notifier)
                          .upsert('weight_reminder_days', v),
                    ),
                    const Divider(height: 1),
                    _TimeSettingTile(
                      label: 'Quiet Window Start',
                      subtitle: 'No push notifications before this hour.',
                      icon: PhosphorIcons.moonStars(),
                      value: settingsMap['quiet_window_start']?.asInt(22) ?? 22,
                      onSave: (v) => ref
                          .read(_settingsProvider.notifier)
                          .upsert('quiet_window_start', v),
                    ),
                    const Divider(height: 1),
                    _TimeSettingTile(
                      label: 'Quiet Window End',
                      subtitle: 'Notifications resume after this hour.',
                      icon: PhosphorIcons.sun(),
                      value: settingsMap['quiet_window_end']?.asInt(8) ?? 8,
                      onSave: (v) => ref
                          .read(_settingsProvider.notifier)
                          .upsert('quiet_window_end', v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // ── Account ────────────────────────────────────────────
            _Section(
              title: 'Account',
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(PhosphorIcons.key(), color: AppColors.textPrimary, size: 22),
                    title: Text('Change Password', style: AppText.bodyMedium),
                    trailing: Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
                    onTap: () => context.push(Routes.changePassword),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s40),

            GymButton.danger(
              label: 'Logout',
              icon: Icon(PhosphorIcons.signOut()),
              onPressed: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Version 1.0.0',
              style: AppText.labelSmall.copyWith(color: AppColors.textHint),
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
            child: const Text('Logout',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppText.labelSmall),
        ),
        GymCard(child: child),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingAll20,
      decoration: BoxDecoration(
        gradient: AppColors.gradientGreen,
        borderRadius: AppSpacing.r20,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 30, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.s16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppText.titleLarge.copyWith(color: Colors.white)),
              Text('Gym Administrator',
                  style: AppText.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

/// A tile that lets the admin edit an integer setting.
class _NumberSettingTile extends StatelessWidget {
  const _NumberSettingTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onSave,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final int value;
  final Future<void> Function(int) onSave;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: AppText.bodyMedium),
      subtitle: Text(subtitle,
          style: AppText.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing: GestureDetector(
        onTap: () => _showEdit(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppSpacing.r8,
          ),
          child: Text('$value days', style: AppText.labelLarge.copyWith(color: AppColors.primary)),
        ),
      ),
      onTap: () => _showEdit(context),
    );
  }

  void _showEdit(BuildContext context) {
    final controller = TextEditingController(text: '$value');
    showDialog<void>(
      context: context,
      builder: (ctx) => _EditDialog(
        title: label,
        controller: controller,
        suffix: 'days',
        onSave: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null && parsed > 0) return onSave(parsed);
          return Future.value();
        },
      ),
    );
  }
}

/// A tile for editing an hour (0-23) value.
class _TimeSettingTile extends StatelessWidget {
  const _TimeSettingTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onSave,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final int value;
  final Future<void> Function(int) onSave;

  String _fmt(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: AppText.bodyMedium),
      subtitle: Text(subtitle,
          style: AppText.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing: GestureDetector(
        onTap: () => _showPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppSpacing.r8,
          ),
          child: Text(_fmt(value),
              style: AppText.labelLarge.copyWith(color: AppColors.primary)),
        ),
      ),
      onTap: () => _showPicker(context),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value, minute: 0),
      helpText: label,
    );
    if (picked != null) await onSave(picked.hour);
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.title,
    required this.controller,
    required this.onSave,
    this.suffix,
  });

  final String title;
  final TextEditingController controller;
  final Future<void> Function(String) onSave;
  final String? suffix;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: GymTextField(
        label: widget.suffix != null ? 'Value (${widget.suffix})' : 'Value',
        hint: widget.controller.text,
        controller: widget.controller,
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave(widget.controller.text.trim());
                  if (context.mounted) Navigator.pop(context);
                },
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
