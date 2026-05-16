import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedPlan == null || _amountController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(memberRepositoryProvider).assignPlan(
            memberId: widget.memberId,
            planId: _selectedPlan!.id,
            finalPrice: double.parse(_amountController.text),
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
    final plansState = ref.watch(plansControllerProvider);

    return Column(
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
                      _amountController.text = plan.defaultPrice.toString();
                    });
                  }
                },
              );
            }).toList(),
          ),
        if (_selectedPlan != null) ...[
          const SizedBox(height: AppSpacing.s32),
          Text(
            'Duration: ${_selectedPlan!.durationDays} days',
            style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s24),
          GymTextField(
            label: 'Paid Amount (৳)',
            hint: '1500',
            controller: _amountController,
            keyboardType: TextInputType.number,
            prefixIcon: Icon(PhosphorIcons.money()),
          ),
          const SizedBox(height: AppSpacing.s40),
          GymButton.primary(
            label: 'Assign Plan',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ],
    );
  }
}
