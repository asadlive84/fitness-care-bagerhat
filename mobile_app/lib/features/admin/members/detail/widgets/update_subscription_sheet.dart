import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

/// Bottom sheet to update an active subscription's end date and price.
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
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _endDate = widget.subscription.endDate;
    _priceController = TextEditingController(
        text: widget.subscription.finalPrice.toStringAsFixed(0));
    _noteController =
        TextEditingController(text: widget.subscription.note ?? '');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(memberRepositoryProvider).updateActiveSubscription(
            memberId: widget.memberId,
            endDate: _endDate,
            finalPrice: price,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // End date picker
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(PhosphorIcons.calendar(), color: Colors.green),
          title: const Text('End Date'),
          subtitle: Text(fmt.format(_endDate)),
          trailing: TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
            child: const Text('Change'),
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        GymTextField(
          label: 'Final Price (৳)',
          hint: '1500',
          controller: _priceController,
          keyboardType: TextInputType.number,
          prefixIcon: Icon(PhosphorIcons.money()),
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
    );
  }
}
