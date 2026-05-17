import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bottom sheet to update an active subscription including billing type settings.
class UpdateSubscriptionSheet extends ConsumerStatefulWidget {
  const UpdateSubscriptionSheet({
    required this.memberId,
    required this.subscription,
    super.key,
  });

  final String memberId;
  final MemberSubscription subscription;

  @override
  ConsumerState<UpdateSubscriptionSheet> createState() =>
      _UpdateSubscriptionSheetState();
}

class _UpdateSubscriptionSheetState
    extends ConsumerState<UpdateSubscriptionSheet> {
  late TextEditingController _priceController;
  late TextEditingController _noteController;
  late TextEditingController _durationController;
  late TextEditingController _graceBefore;
  late TextEditingController _graceAfter;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _billingType;
  DateTime? _prepaidDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.subscription.startDate;
    _endDate = widget.subscription.endDate;
    _billingType = widget.subscription.billingType.isNotEmpty
        ? widget.subscription.billingType
        : 'prepaid';
    _prepaidDueDate = widget.subscription.prepaidDueDate;
    _priceController = TextEditingController(
        text: widget.subscription.finalPrice.toStringAsFixed(0));
    _noteController =
        TextEditingController(text: widget.subscription.note ?? '');
    final days = _endDate.difference(_startDate).inDays;
    _durationController = TextEditingController(text: days.toString());
    _graceBefore = TextEditingController(
        text: widget.subscription.postpaidGraceBefore.toString());
    _graceAfter = TextEditingController(
        text: widget.subscription.postpaidGraceAfter.toString());
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    _durationController.dispose();
    _graceBefore.dispose();
    _graceAfter.dispose();
    super.dispose();
  }

  void _onDurationChanged(String value) {
    final days = int.tryParse(value);
    if (days != null) setState(() => _endDate = _startDate.add(Duration(days: days)));
  }

  Future<void> _submit() async {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(memberRepositoryProvider).updateActiveSubscription(
            memberId: widget.memberId,
            startDate: _startDate,
            endDate: _endDate,
            finalPrice: price,
            billingType: _billingType,
            prepaidDueDate: _billingType == 'prepaid' ? _prepaidDueDate : null,
            postpaidGraceBefore: _billingType == 'postpaid'
                ? (int.tryParse(_graceBefore.text) ?? 5)
                : null,
            postpaidGraceAfter: _billingType == 'postpaid'
                ? (int.tryParse(_graceAfter.text) ?? 5)
                : null,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
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
    final fmt = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Billing type toggle ─────────────────────────────────────────
          Text('Billing Type', style: AppText.labelSmall),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: _BillingTypeButton(
                  label: 'Prepaid',
                  icon: PhosphorIcons.calendarCheck(),
                  isSelected: _billingType == 'prepaid',
                  color: AppColors.success,
                  onTap: () => setState(() => _billingType = 'prepaid'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _BillingTypeButton(
                  label: 'Postpaid',
                  icon: PhosphorIcons.clockCountdown(),
                  isSelected: _billingType == 'postpaid',
                  color: AppColors.info,
                  onTap: () => setState(() => _billingType = 'postpaid'),
                ),
              ),
            ],
          ),

          if (_billingType == 'prepaid') ...[
            const SizedBox(height: AppSpacing.s16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(PhosphorIcons.calendarDot(), color: AppColors.warning),
              title: const Text('Payment Due Date (Optional)'),
              subtitle: Text(
                _prepaidDueDate != null ? fmt.format(_prepaidDueDate!) : 'Not set',
                style: AppText.bodySmall.copyWith(
                  color: _prepaidDueDate != null ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_prepaidDueDate != null)
                    IconButton(
                      icon: Icon(PhosphorIcons.x(), size: 16),
                      onPressed: () => setState(() => _prepaidDueDate = null),
                    ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _prepaidDueDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _prepaidDueDate = picked);
                    },
                    child: Text(_prepaidDueDate != null ? 'Change' : 'Set'),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.s16),
            Container(
              padding: AppSpacing.paddingAll16,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: AppSpacing.r12,
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Window', style: AppText.labelSmall.copyWith(color: AppColors.info)),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      Expanded(
                        child: GymTextField(
                          label: 'Days before end',
                          hint: '5',
                          controller: _graceBefore,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icon(PhosphorIcons.arrowLeft(), size: 18),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: GymTextField(
                          label: 'Days after end',
                          hint: '5',
                          controller: _graceAfter,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icon(PhosphorIcons.arrowRight(), size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.s24),
          const Divider(),

          // ── Dates ────────────────────────────────────────────────────────
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(PhosphorIcons.calendar(), color: AppColors.primary),
            title: const Text('Start Date'),
            subtitle: Text(fmt.format(_startDate)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                    final days = int.tryParse(_durationController.text) ?? 0;
                    _endDate = _startDate.add(Duration(days: days));
                  });
                }
              },
              child: const Text('Change'),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(PhosphorIcons.calendarCheck(), color: AppColors.success),
            title: const Text('End Date'),
            subtitle: Text(fmt.format(_endDate)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() {
                    _endDate = picked;
                    _durationController.text =
                        _endDate.difference(_startDate).inDays.toString();
                  });
                }
              },
              child: const Text('Change'),
            ),
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              Expanded(
                child: GymTextField(
                  label: 'Total Duration (Days)',
                  hint: '30',
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(PhosphorIcons.clock()),
                  onChanged: _onDurationChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: GymTextField(
                  label: 'Final Price (৳)',
                  hint: '1500',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(PhosphorIcons.money()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          GymTextField(
            label: 'Note (Optional)',
            hint: 'e.g. Extended by 1 month',
            controller: _noteController,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.s40),
          GymButton.primary(
            label: 'Save Changes',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _BillingTypeButton extends StatelessWidget {
  const _BillingTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: AppSpacing.r12,
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.labelSmall.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
