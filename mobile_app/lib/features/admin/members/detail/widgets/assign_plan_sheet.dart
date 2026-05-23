import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AssignPlanSheet extends ConsumerStatefulWidget {
  const AssignPlanSheet({required this.memberId, super.key});

  final String memberId;

  @override
  ConsumerState<AssignPlanSheet> createState() => _AssignPlanSheetState();
}

class _AssignPlanSheetState extends ConsumerState<AssignPlanSheet> {
  Plan? _selectedPlan;
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _payController = TextEditingController();
  final _noteController = TextEditingController();
  final _graceBefore = TextEditingController(text: '5');
  final _graceAfter = TextEditingController(text: '5');

  DateTime _startDate = DateTime.now();
  DateTime? _prepaidDueDate;
  String _billingType = 'prepaid';
  String _selectedMethod = 'Cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _durationController.dispose();
    _payController.dispose();
    _noteController.dispose();
    _graceBefore.dispose();
    _graceAfter.dispose();
    super.dispose();
  }

  DateTime get _endDate {
    if (_selectedPlan == null) return _startDate;
    final days = int.tryParse(_durationController.text) ?? _selectedPlan!.durationDays;
    return _startDate.add(Duration(days: days));
  }

  Future<void> _submit() async {
    if (_selectedPlan == null || _amountController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final sub = await ref.read(memberRepositoryProvider).assignPlan(
            memberId: widget.memberId,
            planId: _selectedPlan!.id,
            finalPrice: double.parse(_amountController.text),
            startDate: _startDate,
            billingType: _billingType,
            prepaidDueDate: _billingType == 'prepaid' ? _prepaidDueDate : null,
            postpaidGraceBefore: _billingType == 'postpaid'
                ? (int.tryParse(_graceBefore.text) ?? 5)
                : null,
            postpaidGraceAfter: _billingType == 'postpaid'
                ? (int.tryParse(_graceAfter.text) ?? 5)
                : null,
            note: _noteController.text.trim().isEmpty
                ? _selectedPlan!.name
                : '${_selectedPlan!.name}: ${_noteController.text.trim()}',
          );

      final initialPayment = double.tryParse(_payController.text) ?? 0;
      if (initialPayment > 0) {
        await ref.read(paymentRepositoryProvider).record(
              memberId: widget.memberId,
              subscriptionId: sub.id,
              amount: initialPayment,
              method: _selectedMethod,
            );
      }

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
    final plansState = ref.watch(plansControllerProvider);
    final fmt = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a plan', style: AppText.labelSmall),
          const SizedBox(height: AppSpacing.s12),
          if (plansState.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: plansState.plans.map((plan) {
                final isSelected = _selectedPlan?.id == plan.id;
                return ChoiceChip(
                  label: Text(
                    plan.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.grey.shade200,
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPlan = plan;
                        _amountController.text = plan.defaultPrice.toStringAsFixed(0);
                        _durationController.text = plan.durationDays.toString();
                        _billingType = plan.billingType;
                        _prepaidDueDate = null;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          if (_selectedPlan != null) ...[
            const SizedBox(height: AppSpacing.s24),
            const Divider(),
            const SizedBox(height: AppSpacing.s16),

            // ── Billing type toggle ──────────────────────────────────────
            Text('Billing Type', style: AppText.labelSmall),
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: _BillingTypeButton(
                    label: 'Prepaid',
                    icon: PhosphorIcons.calendarCheck(),
                    description: 'Pay before or on due date',
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
                    description: 'Pay near subscription end',
                    isSelected: _billingType == 'postpaid',
                    color: AppColors.info,
                    onTap: () => setState(() => _billingType = 'postpaid'),
                  ),
                ),
              ],
            ),

            // ── Billing-type specific fields ─────────────────────────────
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
                          initialDate: _prepaidDueDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
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
                            label: 'Days before end date',
                            hint: '5',
                            controller: _graceBefore,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(PhosphorIcons.arrowLeft(), size: 18),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: GymTextField(
                            label: 'Days after end date',
                            hint: '5',
                            controller: _graceAfter,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(PhosphorIcons.arrowRight(), size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Payment window opens ${_graceBefore.text.isEmpty ? 5 : _graceBefore.text} days before and closes ${_graceAfter.text.isEmpty ? 5 : _graceAfter.text} days after the subscription ends.',
                      style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.s24),
            const Divider(),
            const SizedBox(height: AppSpacing.s16),

            // ── Dates ────────────────────────────────────────────────────
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
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: const Text('Change'),
              ),
            ),

            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GymTextField(
                    label: 'Duration (Days)',
                    hint: '30',
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icon(PhosphorIcons.clock()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Date (Auto)', style: AppText.labelSmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: AppSpacing.r12,
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.calendarCheck(), size: 18, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text(fmt.format(_endDate), style: AppText.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s20),
            GymTextField(
              label: 'Final Price (৳)',
              hint: '1500',
              controller: _amountController,
              keyboardType: TextInputType.number,
              prefixIcon: Icon(PhosphorIcons.money()),
            ),

            const SizedBox(height: AppSpacing.s24),
            const Divider(),
            const SizedBox(height: AppSpacing.s16),
            Text('Initial Payment (Optional)', style: AppText.titleSmall),
            const SizedBox(height: AppSpacing.s16),
            GymTextField(
              label: 'Pay Now (৳)',
              hint: '0',
              controller: _payController,
              keyboardType: TextInputType.number,
              prefixIcon: Icon(PhosphorIcons.handCoins()),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('Payment Method', style: AppText.labelSmall),
            const SizedBox(height: AppSpacing.s12),
            _MethodSelector(
              selectedMethod: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val),
            ),
            const SizedBox(height: AppSpacing.s20),
            GymTextField(
              label: 'Note (Optional)',
              hint: 'e.g. Discount applied',
              controller: _noteController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.s40),
            GymButton.primary(
              label: 'Assign Plan',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ],
      ),
    );
  }
}

class _BillingTypeButton extends StatelessWidget {
  const _BillingTypeButton({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: AppSpacing.paddingAll16,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: AppSpacing.r12,
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppText.titleSmall.copyWith(
                    color: isSelected ? color : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppText.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.selectedMethod, required this.onChanged});

  final String selectedMethod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final methods = <(String id, String label, IconData icon)>[
      ('Cash', 'Cash', PhosphorIcons.money()),
      ('bKash', 'bKash', PhosphorIcons.deviceMobile()),
      ('Nagad', 'Nagad', PhosphorIcons.deviceMobile()),
      ('Card', 'Card', PhosphorIcons.creditCard()),
    ];

    return Row(
      children: methods.map((m) {
        final isSelected = selectedMethod == m.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: AppSpacing.r12,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                ),
                child: Column(
                  children: [
                    Icon(m.$3, color: isSelected ? Colors.white : AppColors.textSecondary, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      m.$2,
                      style: AppText.labelSmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
