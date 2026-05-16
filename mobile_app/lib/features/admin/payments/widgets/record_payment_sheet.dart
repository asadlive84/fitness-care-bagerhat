import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payments_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({
    required this.memberId,
    required this.memberName,
    required this.subscriptionId,
    this.initialAmount,
    super.key,
  });

  final String memberId;
  final String memberName;
  final String subscriptionId;
  final double? initialAmount;

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedMethod = 'Cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_amountController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(paymentRepositoryProvider).record(
            memberId: widget.memberId,
            subscriptionId: widget.subscriptionId,
            amount: double.parse(_amountController.text),
            method: _selectedMethod,
          );
      
      await ref.read(paymentsControllerProvider.notifier).loadSummary();
      
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recording payment for ${widget.memberName}',
          style: AppText.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s24),
        GymTextField(
          label: 'Amount (৳)',
          hint: '0.00',
          controller: _amountController,
          keyboardType: TextInputType.number,
          prefixIcon: Icon(PhosphorIcons.money()),
        ),
        const SizedBox(height: AppSpacing.s20),
        Text('Payment Method', style: AppText.labelSmall),
        const SizedBox(height: AppSpacing.s12),
        _MethodSelector(
          selectedMethod: _selectedMethod,
          onChanged: (val) => setState(() => _selectedMethod = val),
        ),
        const SizedBox(height: AppSpacing.s20),
        GymTextField(
          label: 'Note (Optional)',
          hint: 'e.g. Monthly fee for May',
          controller: _noteController,
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.s40),
        GymButton.primary(
          label: 'Record Payment',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
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
    // IDs must match backend validation: Cash | bKash | Nagad | Card
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
