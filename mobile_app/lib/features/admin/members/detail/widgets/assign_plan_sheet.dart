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
  const AssignPlanSheet({
    required this.memberId,
    super.key,
  });

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
  DateTime _startDate = DateTime.now();
  String _selectedMethod = 'Cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _durationController.dispose();
    _payController.dispose();
    _noteController.dispose();
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
            note: _noteController.text.trim().isEmpty
                ? _selectedPlan!.name
                : '${_selectedPlan!.name}: ${_noteController.text.trim()}',
          );

      // Record initial payment if provided
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
                  label: Text(plan.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPlan = plan;
                        _amountController.text = plan.defaultPrice.toStringAsFixed(0);
                        _durationController.text = plan.durationDays.toString();
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
            
            // Start Date Picker
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

            // Duration and End Date Preview
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

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({
    required this.selectedMethod,
    required this.onChanged,
  });

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
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      m.$3,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      size: 20,
                    ),
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
