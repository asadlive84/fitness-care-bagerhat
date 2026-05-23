import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PlanForm extends ConsumerStatefulWidget {
  const PlanForm({super.key, this.plan});

  final Plan? plan;

  @override
  ConsumerState<PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<PlanForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  bool _isLoading = false;
  String _billingType = 'prepaid';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _priceController = TextEditingController(
      text: widget.plan?.defaultPrice.toStringAsFixed(0) ?? '',
    );
    _durationController = TextEditingController(
      text: widget.plan?.durationDays.toString() ?? '',
    );
    _billingType = widget.plan?.billingType ?? 'prepaid';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = double.tryParse(_priceController.text.trim());
    final days = int.tryParse(_durationController.text.trim());

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price greater than 0')),
      );
      return;
    }
    if (days == null || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid duration in days')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'default_price': price,
        'duration_days': days,
        'billing_type': _billingType,
      };

      if (widget.plan == null) {
        await ref.read(planRepositoryProvider).create(data);
      } else {
        await ref.read(planRepositoryProvider).update(widget.plan!.id, data);
      }

      // Creation / update succeeded on the backend — close the sheet
      // immediately so the admin gets instant feedback.
      // Then trigger a background reload; if the reload itself fails for any
      // reason (e.g. a parse error), the controller's catch block resets
      // isLoading so the list screen never gets stuck on shimmers.
      if (mounted) Navigator.pop(context);

      // unawaited — fire and forget
      ref.read(plansControllerProvider.notifier).load();
    } catch (e) {
      // API or network error — keep the form open, show a clear message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GymTextField(
            label: 'Plan Name',
            hint: 'e.g. Monthly Basic',
            controller: _nameController,
            prefixIcon: Icon(PhosphorIcons.tag()),
            validator: (v) {
              if (v == null || v.trim().length < 2) {
                return 'At least 2 characters required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              Expanded(
                child: GymTextField(
                  label: 'Price (৳)',
                  hint: '1500',
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icon(PhosphorIcons.money()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: GymTextField(
                  label: 'Duration (days)',
                  hint: '30',
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(PhosphorIcons.clock()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Must be ≥ 1';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          DropdownButtonFormField<String>(
            value: _billingType,
            decoration: InputDecoration(
              labelText: 'Billing Type',
              prefixIcon: Icon(PhosphorIcons.creditCard()),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.r12,
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
            items: const [
              DropdownMenuItem(value: 'prepaid', child: Text('Prepaid (Pay before)')),
              DropdownMenuItem(value: 'postpaid', child: Text('Postpaid (Pay after)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _billingType = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.s40),
          GymButton.primary(
            label: widget.plan == null ? 'Create Plan' : 'Save Changes',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
