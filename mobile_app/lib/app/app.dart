import 'package:fitness_care_bagerhat/app/router/router.dart';
import 'package:fitness_care_bagerhat/app/theme/app_theme.dart';
import 'package:fitness_care_bagerhat/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ## FitnessCareApp
///
/// Root widget of the application.
/// Uses [MaterialApp.router] with [GoRouter] for navigation
/// and [Riverpod] for state management.
class FitnessCareApp extends ConsumerWidget {
  const FitnessCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Fitness Care Bagerhat',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Navigation
      routerConfig: router,

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
