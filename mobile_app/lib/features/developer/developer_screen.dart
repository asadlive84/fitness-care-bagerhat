import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  Future<void> _launchX() async {
    final url = Uri.parse('https://x.com/asadlive84');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Info'),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.paddingAll24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.code(),
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.s32),
              Text(
                'Developed By',
                style: AppText.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Asaduzzaman Sohel',
                style: AppText.headlineLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const SizedBox(width: 40, child: Divider(thickness: 2)),
              const SizedBox(height: AppSpacing.s24),
              Text(
                'Backend Software Developer',
                textAlign: TextAlign.center,
                style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s40),
              GymButton.secondary(
                label: '@x.com/asadlive84',
                icon: Icon(PhosphorIcons.xLogo(), color: AppColors.textPrimary),
                onPressed: _launchX,
              ),
              const SizedBox(height: AppSpacing.s80),
              Text(
                'v1.0.0',
                style: AppText.labelSmall.copyWith(color: AppColors.divider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
