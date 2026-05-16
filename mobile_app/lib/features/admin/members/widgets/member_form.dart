import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Comprehensive member form for create and edit flows.
///
/// Covers all profile fields: basic info, physical stats, identity, address,
/// and preferences (religion, blood group, hobbies).
class MemberForm extends StatefulWidget {
  const MemberForm({
    required this.onSubmit,
    required this.isLoading,
    super.key,
    this.member,
  });

  final Member? member;
  final bool isLoading;
  final Future<void> Function(MemberFormData data) onSubmit;

  @override
  State<MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<MemberForm> {
  final _formKey = GlobalKey<FormState>();

  // ── Basic ──────────────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _goalCtrl;
  late final TextEditingController _emergencyPhoneCtrl;

  // ── Physical ───────────────────────────────────────────────────────────────
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightFtCtrl;
  late final TextEditingController _heightInCtrl;
  DateTime? _dateOfBirth;
  DateTime? _joinDate;

  // ── Identity ───────────────────────────────────────────────────────────────
  late final TextEditingController _nidCtrl;
  late final TextEditingController _occupationCtrl;

  // ── Address ────────────────────────────────────────────────────────────────
  late final TextEditingController _presentAddressCtrl;
  late final TextEditingController _permanentAddressCtrl;

  // ── Preferences ────────────────────────────────────────────────────────────
  String? _religion;
  String? _bloodGroup;
  final Set<String> _hobbies = {};

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _phoneCtrl = TextEditingController(text: m?.phone ?? '');
    _goalCtrl = TextEditingController(text: m?.goal ?? '');
    _emergencyPhoneCtrl = TextEditingController(text: m?.emergencyPhone ?? '');
    _weightCtrl = TextEditingController(text: m?.currentWeight?.toStringAsFixed(1) ?? '');
    
    // Convert CM to Ft/In for initial value
    if (m?.heightCm != null) {
      final totalInches = m!.heightCm! / 2.54;
      _heightFtCtrl = TextEditingController(text: (totalInches / 12).floor().toString());
      _heightInCtrl = TextEditingController(text: (totalInches % 12).round().toString());
    } else {
      _heightFtCtrl = TextEditingController();
      _heightInCtrl = TextEditingController();
    }

    _nidCtrl = TextEditingController(text: m?.nid ?? '');
    _occupationCtrl = TextEditingController(text: m?.occupation ?? '');
    _presentAddressCtrl = TextEditingController(text: m?.presentAddress ?? '');
    _permanentAddressCtrl = TextEditingController(text: m?.permanentAddress ?? '');
    _dateOfBirth = m?.dateOfBirth;
    _joinDate = m?.joinDate;
    _religion = m?.religion;
    _bloodGroup = m?.bloodGroup;
    _hobbies.addAll(m?.hobbies ?? []);

    // Listen to height changes for BMI preview
    _heightFtCtrl.addListener(() => setState(() {}));
    _heightInCtrl.addListener(() => setState(() {}));
    _weightCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _goalCtrl, _emergencyPhoneCtrl,
      _weightCtrl, _heightFtCtrl, _heightInCtrl, _nidCtrl, _occupationCtrl,
      _presentAddressCtrl, _permanentAddressCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _currentHeightCm {
    final ft = int.tryParse(_heightFtCtrl.text.trim()) ?? 0;
    final inch = int.tryParse(_heightInCtrl.text.trim()) ?? 0;
    if (ft == 0 && inch == 0) return null;
    return (ft * 30.48) + (inch * 2.54);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.onSubmit(
      MemberFormData(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        goal: _goalCtrl.text.trim().isEmpty ? null : _goalCtrl.text.trim(),
        currentWeight: double.tryParse(_weightCtrl.text.trim()),
        heightCm: _currentHeightCm,
        joinDate: _joinDate,
        dateOfBirth: _dateOfBirth,
        religion: _religion,
        bloodGroup: _bloodGroup,
        hobbies: _hobbies.toList(),
        presentAddress: _presentAddressCtrl.text.trim().isEmpty
            ? null
            : _presentAddressCtrl.text.trim(),
        permanentAddress: _permanentAddressCtrl.text.trim().isEmpty
            ? null
            : _permanentAddressCtrl.text.trim(),
        occupation: _occupationCtrl.text.trim().isEmpty ? null : _occupationCtrl.text.trim(),
        nid: _nidCtrl.text.trim().isEmpty ? null : _nidCtrl.text.trim(),
        emergencyPhone: _emergencyPhoneCtrl.text.trim().isEmpty
            ? null
            : _emergencyPhoneCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Basic info ──────────────────────────────────────────────────
          _SectionHeader(label: 'Basic Information', icon: PhosphorIcons.user()),
          const SizedBox(height: AppSpacing.s16),

          GymTextField(
            label: 'Full Name *',
            hint: 'e.g. Karim Ahmed',
            controller: _nameCtrl,
            prefixIcon: Icon(PhosphorIcons.user()),
            validator: (v) => (v == null || v.trim().length < 2)
                ? 'At least 2 characters'
                : null,
          ),
          const SizedBox(height: AppSpacing.s16),

          GymTextField(
            label: 'Phone Number *',
            hint: '01711-XXXXXX',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icon(PhosphorIcons.phone()),
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Enter a valid phone number'
                : null,
          ),
          const SizedBox(height: AppSpacing.s16),

          GymTextField(
            label: 'Emergency Contact Phone',
            hint: '01X-XXXXXXXX',
            controller: _emergencyPhoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icon(PhosphorIcons.phoneCall()),
          ),
          const SizedBox(height: AppSpacing.s16),

          GymTextField(
            label: 'Fitness Goal',
            hint: 'e.g. Weight loss, Muscle gain',
            controller: _goalCtrl,
            prefixIcon: Icon(PhosphorIcons.target()),
          ),
          const SizedBox(height: AppSpacing.s16),

          Row(
            children: [
              Expanded(child: _DatePickerTile(
                label: 'Join Date',
                value: _joinDate,
                onPicked: (d) => setState(() => _joinDate = d),
              )),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: _DatePickerTile(
                label: 'Date of Birth',
                value: _dateOfBirth,
                onPicked: (d) => setState(() => _dateOfBirth = d),
                maxDate: DateTime.now(),
              )),
            ],
          ),

          const SizedBox(height: AppSpacing.s32),

          // ── Physical stats ──────────────────────────────────────────────
          _SectionHeader(label: 'Physical Stats', icon: PhosphorIcons.scales()),
          const SizedBox(height: AppSpacing.s16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: GymTextField(
                  label: 'Weight (kg)',
                  hint: '72.5',
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icon(PhosphorIcons.scales()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0 || n > 500) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Height', style: AppText.labelSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GymTextField(
                            hint: '5',
                            controller: _heightFtCtrl,
                            keyboardType: TextInputType.number,
                            suffixText: 'ft',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 0 || n > 9) return '!';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GymTextField(
                            hint: '7',
                            controller: _heightInCtrl,
                            keyboardType: TextInputType.number,
                            suffixText: 'in',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 0 || n > 11) return '!';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // BMI preview
          if (_weightCtrl.text.isNotEmpty && (_heightFtCtrl.text.isNotEmpty || _heightInCtrl.text.isNotEmpty))
            _BmiPreview(
              weight: double.tryParse(_weightCtrl.text),
              heightCm: _currentHeightCm,
            ),

          const SizedBox(height: AppSpacing.s16),

          // Blood group
          _DropdownField(
            label: 'Blood Group',
            value: _bloodGroup,
            items: kBloodGroups,
            icon: PhosphorIcons.drop(),
            onChanged: (v) => setState(() => _bloodGroup = v),
          ),

          const SizedBox(height: AppSpacing.s32),

          // ── Identity ────────────────────────────────────────────────────
          _SectionHeader(label: 'Identity & Work', icon: PhosphorIcons.identificationCard()),
          const SizedBox(height: AppSpacing.s16),

          GymTextField(
            label: 'NID Number',
            hint: '1234567890',
            controller: _nidCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icon(PhosphorIcons.identificationCard()),
          ),
          const SizedBox(height: AppSpacing.s16),

          GymTextField(
            label: 'Occupation',
            hint: 'e.g. Teacher, Engineer',
            controller: _occupationCtrl,
            prefixIcon: Icon(PhosphorIcons.briefcase()),
          ),
          const SizedBox(height: AppSpacing.s16),

          _DropdownField(
            label: 'Religion',
            value: _religion,
            items: kReligions,
            icon: PhosphorIcons.book(),
            onChanged: (v) => setState(() => _religion = v),
          ),

          const SizedBox(height: AppSpacing.s32),

          // ── Address ─────────────────────────────────────────────────────
          _SectionHeader(label: 'Address', icon: PhosphorIcons.mapPin()),
          const SizedBox(height: AppSpacing.s16),

          GymTextField(
            label: 'Present Address',
            hint: 'Village/Road, Upazila, District',
            controller: _presentAddressCtrl,
            maxLines: 2,
            prefixIcon: Icon(PhosphorIcons.mapPin()),
          ),
          const SizedBox(height: AppSpacing.s16),

          GymTextField(
            label: 'Permanent Address',
            hint: 'Village/Road, Upazila, District',
            controller: _permanentAddressCtrl,
            maxLines: 2,
            prefixIcon: Icon(PhosphorIcons.house()),
          ),

          const SizedBox(height: AppSpacing.s32),

          // ── Hobbies ─────────────────────────────────────────────────────
          _SectionHeader(label: 'Hobbies', icon: PhosphorIcons.star()),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: kHobbies.map((h) {
              final selected = _hobbies.contains(h);
              return FilterChip(
                label: Text(h),
                selected: selected,
                onSelected: (on) => setState(() {
                  if (on) _hobbies.add(h);
                  else _hobbies.remove(h);
                }),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: AppText.labelSmall.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.s40),
          GymButton.primary(
            label: widget.member == null ? 'Create Member' : 'Save Changes',
            isLoading: widget.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Data class returned by the form ──────────────────────────────────────────

class MemberFormData {
  const MemberFormData({
    required this.name,
    required this.phone,
    this.goal,
    this.currentWeight,
    this.heightCm,
    this.joinDate,
    this.dateOfBirth,
    this.religion,
    this.bloodGroup,
    this.hobbies = const [],
    this.presentAddress,
    this.permanentAddress,
    this.occupation,
    this.nid,
    this.emergencyPhone,
  });

  final String name;
  final String phone;
  final String? goal;
  final double? currentWeight;
  final double? heightCm;
  final DateTime? joinDate;
  final DateTime? dateOfBirth;
  final String? religion;
  final String? bloodGroup;
  final List<String> hobbies;
  final String? presentAddress;
  final String? permanentAddress;
  final String? occupation;
  final String? nid;
  final String? emergencyPhone;
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.s8),
        Text(label, style: AppText.titleSmall.copyWith(color: AppColors.primary)),
        const SizedBox(width: AppSpacing.s8),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.onPicked,
    this.value,
    this.maxDate,
  });

  final String label;
  final DateTime? value;
  final DateTime? maxDate;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1920),
          lastDate: maxDate ?? DateTime.now().add(const Duration(days: 3650)),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: AppSpacing.r12,
        ),
        child: Row(
          children: [
            Icon(PhosphorIcons.calendar(), size: 18, color: AppColors.textHint),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppText.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
                  Text(
                    value != null ? fmt.format(value!) : 'Tap to select',
                    style: AppText.bodySmall.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.value,
  });

  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: AppSpacing.r12),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('— Select —')),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: onChanged,
    );
  }
}

class _BmiPreview extends StatelessWidget {
  const _BmiPreview({this.weight, this.heightCm});
  final double? weight;
  final double? heightCm;

  @override
  Widget build(BuildContext context) {
    if (weight == null || heightCm == null || heightCm! <= 0) {
      return const SizedBox.shrink();
    }
    final h = heightCm! / 100.0;
    final bmi = weight! / (h * h);
    final String category;
    final Color color;
    if (bmi < 18.5) {
      category = 'Underweight';
      color = AppColors.info;
    } else if (bmi < 25) {
      category = 'Normal';
      color = AppColors.success;
    } else if (bmi < 30) {
      category = 'Overweight';
      color = AppColors.warning;
    } else {
      category = 'Obese';
      color = AppColors.error;
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Row(
        children: [
          Icon(PhosphorIcons.info(), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'BMI: ${bmi.toStringAsFixed(1)} — $category',
            style: AppText.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
