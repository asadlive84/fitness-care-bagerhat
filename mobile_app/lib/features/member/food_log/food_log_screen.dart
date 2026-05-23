import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/settings/settings_repository.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/member/food_log/food_log.dart';
import 'package:fitness_care_bagerhat/features/member/food_log/food_log_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  bool _isUploading = false;
  String _uploadStatus = '';

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Compressing image...';
    });

    try {
      // Compress image to save mobile bandwidth & ensure fast upload
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.absolute.path}/compressed_food_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedFile == null) {
        throw Exception('Failed to compress image.');
      }

      setState(() {
        _uploadStatus = 'AI is analyzing your meal...';
      });

      // Log meal to server (uploads image & runs AI analysis)
      final nutrition = await ref
          .read(foodLogControllerProvider.notifier)
          .logMeal(compressedFile.path);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        // Show a beautiful success feedback sheet
        _showSuccessSheet(nutrition);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze meal: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Text(
                'Add Food/Meal Log',
                style: AppText.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIcons.camera(), color: AppColors.primary),
              ),
              title: const Text('Capture with Camera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIcons.image(), color: AppColors.accent),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.s24),
          ],
        ),
      ),
    );
  }

  void _showSuccessSheet(NutritionData nutrition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.3),
                  borderRadius: AppSpacing.rFull,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Row(
              children: [
                Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                    color: AppColors.accent, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Meal Analysis Successful!',
                    style: AppText.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              nutrition.name,
              style: AppText.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.s20),
            Container(
              padding: AppSpacing.paddingAll16,
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: AppSpacing.r16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroBadge(
                    label: 'Calories',
                    value: '${nutrition.calories.round()} kcal',
                    color: AppColors.primary,
                  ),
                  _MacroBadge(
                    label: 'Protein',
                    value: '${nutrition.protein.round()}g',
                    color: AppColors.success,
                  ),
                  _MacroBadge(
                    label: 'Carbs',
                    value: '${nutrition.carbs.round()}g',
                    color: AppColors.info,
                  ),
                  _MacroBadge(
                    label: 'Fats',
                    value: '${nutrition.fats.round()}g',
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(
              'Nutritionist Insight:',
              style: AppText.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              nutrition.analysis,
              style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s32),
            GymButton.primary(
              label: 'Got it, thanks!',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodLogControllerProvider);
    final baseUrl = ref.watch(settingsRepositoryProvider).baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meal Visualizer'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(foodLogControllerProvider.notifier).load(),
            child: state.when(
              loading: () => const _LoadingState(),
              error: (err, _) => GymErrorState(
                message: err.toString(),
                onRetry: () =>
                    ref.read(foodLogControllerProvider.notifier).load(),
              ),
              data: (logs) {
                // Calculate today's stats
                double totalCalories = 0;
                double totalProtein = 0;
                double totalCarbs = 0;
                double totalFats = 0;

                final today = DateTime.now();
                final todayLogs = logs.where((log) =>
                    log.createdAt.year == today.year &&
                    log.createdAt.month == today.month &&
                    log.createdAt.day == today.day);

                for (var log in todayLogs) {
                  totalCalories += log.nutrition.calories;
                  totalProtein += log.nutrition.protein;
                  totalCarbs += log.nutrition.carbs;
                  totalFats += log.nutrition.fats;
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NutritionDashboard(
                        calories: totalCalories,
                        protein: totalProtein,
                        carbs: totalCarbs,
                        fats: totalFats,
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s20),
                        child: Text(
                          'Meal History',
                          style: AppText.titleMedium
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      if (logs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.s48),
                          child: GymEmptyState(
                            animationPath: 'assets/animations/empty_members.json',
                            message:
                                'No food logs uploaded yet.\nUpload your first meal for AI analysis!',
                            actionLabel: 'Log Food',
                            onAction: _showImageSourceOptions,
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s20,
                            vertical: AppSpacing.s8,
                          ),
                          itemCount: logs.length,
                          separatorBuilder: (c, i) =>
                              const SizedBox(height: AppSpacing.s16),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return _MealLogCard(log: log, baseUrl: baseUrl);
                          },
                        ),
                      const SizedBox(height: AppSpacing.s80),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.6),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        Text(
                          _uploadStatus,
                          style: AppText.titleSmall
                              .copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Powered by Google Gemini Vision AI',
                          style: AppText.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceOptions,
        backgroundColor: AppColors.accent,
        icon: Icon(PhosphorIcons.bowlFood(PhosphorIconsStyle.fill),
            color: Colors.white),
        label: const Text(
          'Log Meal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _NutritionDashboard extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  const _NutritionDashboard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  @override
  Widget build(BuildContext context) {
    // Standard recommended intake for active gym members
    const targetCalories = 2200.0;
    const targetProtein = 130.0;
    const targetCarbs = 240.0;
    const targetFats = 70.0;

    final calorieProgress = (calories / targetCalories).clamp(0.0, 1.0);
    final proteinProgress = (protein / targetProtein).clamp(0.0, 1.0);
    final carbsProgress = (carbs / targetCarbs).clamp(0.0, 1.0);
    final fatsProgress = (fats / targetFats).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.s20),
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientGreen,
        borderRadius: AppSpacing.r24,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S INTAKE",
                    style: AppText.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${calories.round()}',
                        style: AppText.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ ${targetCalories.round()} kcal',
                        style: AppText.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          ClipRRect(
            borderRadius: AppSpacing.rFull,
            child: LinearProgressIndicator(
              value: calorieProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: AppSpacing.s20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DashboardMacroItem(
                label: 'PROTEIN',
                current: protein,
                target: targetProtein,
                progress: proteinProgress,
                color: Colors.lightGreenAccent,
              ),
              _DashboardMacroItem(
                label: 'CARBS',
                current: carbs,
                target: targetCarbs,
                progress: carbsProgress,
                color: Colors.lightBlueAccent,
              ),
              _DashboardMacroItem(
                label: 'FATS',
                current: fats,
                target: targetFats,
                progress: fatsProgress,
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardMacroItem extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final double progress;
  final Color color;

  const _DashboardMacroItem({
    required this.label,
    required this.current,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.labelSmall.copyWith(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${current.round()}/${target.round()}g',
            style: AppText.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: AppSpacing.rFull,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppText.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: AppText.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _MealLogCard extends StatelessWidget {
  final FoodLog log;
  final String baseUrl;

  const _MealLogCard({
    required this.log,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = log.imageUrl.startsWith('http')
        ? log.imageUrl
        : '$baseUrl${log.imageUrl}';

    return GestureDetector(
      onTap: () => _showMealDetailSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.r20,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.divider.withOpacity(0.3)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CachedNetworkImage(
                    imageUrl: fullUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, url) => Container(
                      color: AppColors.bgLight,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (c, url, err) => Container(
                      color: AppColors.bgLight,
                      child: Icon(
                        PhosphorIcons.bowlFood(),
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              log.nutrition.name,
                              style: AppText.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('jm').format(log.createdAt),
                            style: AppText.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${log.nutrition.calories.round()} kcal',
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _MacroMiniBadge(
                            label: 'P',
                            value: '${log.nutrition.protein.round()}g',
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          _MacroMiniBadge(
                            label: 'C',
                            value: '${log.nutrition.carbs.round()}g',
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          _MacroMiniBadge(
                            label: 'F',
                            value: '${log.nutrition.fats.round()}g',
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMealDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: log.imageUrl.startsWith('http')
                        ? log.imageUrl
                        : '$baseUrl${log.imageUrl}',
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log.nutrition.name,
                          style: AppText.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy · jm').format(log.createdAt),
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MacroBadge(
                        label: 'Calories',
                        value: '${log.nutrition.calories.round()} kcal',
                        color: AppColors.primary,
                      ),
                      _MacroBadge(
                        label: 'Protein',
                        value: '${log.nutrition.protein.round()}g',
                        color: AppColors.success,
                      ),
                      _MacroBadge(
                        label: 'Carbs',
                        value: '${log.nutrition.carbs.round()}g',
                        color: AppColors.info,
                      ),
                      _MacroBadge(
                        label: 'Fats',
                        value: '${log.nutrition.fats.round()}g',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'AI Analysis Details:',
                    style: AppText.titleSmall
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    log.nutrition.analysis,
                    style: AppText.bodyMedium
                        .copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                  if (log.deviceModel != null && log.deviceModel!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      'Captured using ${log.deviceModel}',
                      style: AppText.labelSmall.copyWith(
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroMiniBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroMiniBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppText.labelSmall.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: AppText.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.s20),
      child: Column(
        children: [
          GymShimmer.card(height: 200),
          SizedBox(height: AppSpacing.s24),
          GymShimmer.line(height: 20),
          SizedBox(height: AppSpacing.s16),
          GymShimmer.card(height: 100),
          SizedBox(height: AppSpacing.s16),
          GymShimmer.card(height: 100),
        ],
      ),
    );
  }
}
