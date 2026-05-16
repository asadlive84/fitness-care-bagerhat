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
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name);
        TextEditingController(text: ''); // Removed description
    _priceController =
        TextEditingController(text: widget.plan?.defaultPrice.toString());
    _durationController =
        TextEditingController(text: widget.plan?.durationDays.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text),
          'duration_days': int.parse(_durationController.text),
        };

        if (widget.plan == null) {
          await ref.read(planRepositoryProvider).create(data);
        } else {
          await ref.read(planRepositoryProvider).update(widget.plan!.id, data);
        }

        ref.read(plansControllerProvider.notifier).load();
        if (mounted) Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          GymTextField(
            label: 'Plan Name',
            hint: 'e.g. Monthly Basic',
            controller: _nameController,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: AppSpacing.s20),
          GymTextField(
            label: 'Description',
            hint: 'Describe what\'s included...',
            controller: _descriptionController,
            maxLines: 3,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              Expanded(
                child: GymTextField(
                  label: 'Price (৳)',
                  hint: '1500',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(PhosphorIcons.money()),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: GymTextField(
                  label: 'Duration (Days)',
                  hint: '30',
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(PhosphorIcons.clock()),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
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
