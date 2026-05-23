import 'dart:io';

import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_avatar.dart';
import 'package:fitness_care_bagerhat/core/settings/settings_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:fitness_care_bagerhat/features/member/profile/member_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// ## EditProfileScreen
///
/// Lets a member update their name, goal, and current weight.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({required this.member, super.key});

  final Member member;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _goalController;
  late final TextEditingController _weightController;
  String? _budgetLevel;
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _goalController = TextEditingController(text: widget.member.goal ?? '');
    _weightController = TextEditingController(
      text: widget.member.currentWeight?.toString() ?? '',
    );
    _budgetLevel = widget.member.budgetLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path, 
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );
      
      if (result != null) {
        setState(() {
          _pickedImage = File(result.path);
        });
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(PhosphorIcons.camera()),
              title: const Text('Take a picture'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.image()),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(memberProfileRepositoryProvider);
      String? newProfilePictureUrl = widget.member.profilePictureUrl;
      
      if (_pickedImage != null) {
        newProfilePictureUrl = await repo.uploadImage(_pickedImage!.path);
      }

      await repo.updateProfile(
            name: _nameController.text.trim(),
            goal: _goalController.text.trim().isEmpty
                ? null
                : _goalController.text.trim(),
            currentWeight: _weightController.text.trim().isEmpty
                ? null
                : double.tryParse(_weightController.text.trim()),
          );
          
      if (_budgetLevel != widget.member.budgetLevel || _pickedImage != null) {
        await repo.updateAIProfile(
          budgetLevel: _budgetLevel,
          profilePictureUrl: newProfilePictureUrl,
        );
      }

      // Refresh the home screen state so it reflects new data
      await ref.read(memberHomeControllerProvider.notifier).load();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll24,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your profile information below.',
                style: AppText.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.s32),
              
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerModal,
                  child: Stack(
                    children: [
                      if (_pickedImage != null)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: FileImage(_pickedImage!),
                        )
                      else if (widget.member.profilePictureUrl != null && widget.member.profilePictureUrl!.isNotEmpty)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            widget.member.profilePictureUrl!.startsWith('http') 
                                ? widget.member.profilePictureUrl! 
                                : '${ref.read(settingsRepositoryProvider).baseUrl}${widget.member.profilePictureUrl!}'
                          ),
                        )
                      else
                        GymAvatar(name: widget.member.name, size: 100),
                        
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s32),
              
              GymTextField(
                label: 'Full Name',
                hint: 'Your name',
                controller: _nameController,
                prefixIcon: Icon(PhosphorIcons.user()),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Name must be at least 2 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.s20),
              GymTextField(
                label: 'Goal (Optional)',
                hint: 'e.g. Weight loss, Muscle gain',
                controller: _goalController,
                prefixIcon: Icon(PhosphorIcons.target()),
              ),
              const SizedBox(height: AppSpacing.s20),
              GymTextField(
                label: 'Current Weight (kg)',
                hint: 'e.g. 72.5',
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(PhosphorIcons.scales()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0 || parsed > 500) {
                    return 'Enter a valid weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s20),
              
              Text('AI Settings', style: AppText.titleMedium),
              const SizedBox(height: AppSpacing.s16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.r12,
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _budgetLevel,
                    hint: const Text('Diet Budget Level'),
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low Budget (Student/Economy)')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium Budget (Standard)')),
                      DropdownMenuItem(value: 'High', child: Text('High Budget (Premium/Organic)')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _budgetLevel = val;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.s40),
              GymButton.primary(
                label: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
