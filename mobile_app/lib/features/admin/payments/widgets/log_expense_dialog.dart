import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/financials_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LogExpenseDialog extends ConsumerStatefulWidget {
  const LogExpenseDialog({super.key});

  @override
  ConsumerState<LogExpenseDialog> createState() => _LogExpenseDialogState();
}

class _LogExpenseDialogState extends ConsumerState<LogExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descController;
  
  String _category = 'Water';
  DateTime _spentAt = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select Date of Expense',
    );
    if (picked != null) {
      setState(() => _spentAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(financialsControllerProvider.notifier).logExpense(
          amount: amount,
          description: _descController.text.trim(),
          category: _category,
          spentAt: _spentAt,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense logged successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log expense. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GymTextField(
            label: 'Amount (৳)',
            hint: 'e.g. 500',
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icon(PhosphorIcons.money()),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Must be greater than 0';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s20),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              labelText: 'Expense Category',
              prefixIcon: Icon(PhosphorIcons.tag()),
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.r12,
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Water', child: Text('Water / Refreshment')),
              DropdownMenuItem(value: 'Bill', child: Text('Utility Bill / Electricity')),
              DropdownMenuItem(value: 'Salary', child: Text('Staff Salary')),
              DropdownMenuItem(value: 'Rent', child: Text('Gym Rent')),
              DropdownMenuItem(value: 'Maintenance', child: Text('Equipment Maintenance')),
              DropdownMenuItem(value: 'Others', child: Text('Other Operational Costs')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.s20),
          GymTextField(
            label: 'Description / Note',
            hint: 'e.g. Water jar purchase for reception',
            controller: _descController,
            prefixIcon: Icon(PhosphorIcons.fileText()),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length < 3) return 'At least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s20),
          InkWell(
            onTap: _pickDate,
            borderRadius: AppSpacing.r12,
            child: Container(
              padding: AppSpacing.paddingAll16,
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: AppSpacing.r12,
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIcons.calendar(), color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Date',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMMM yyyy').format(_spentAt),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorIcons.caretRight(), color: AppColors.textHint),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
          GymButton.primary(
            label: 'Record Expense',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
