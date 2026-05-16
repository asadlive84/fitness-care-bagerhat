import 'dart:async';
import 'dart:developer';

import 'package:fitness_care_bagerhat/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fitness_care_bagerhat/core/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ## bootstrap
///
/// Initializes all services and runs the app.
/// Handles global error boundaries.
Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      await dotenv.load(fileName: '.env');

      // Initialize Firebase (Only if config is provided later)
      // await Firebase.initializeApp();

      // Initialize storage
      final prefs = await SharedPreferences.getInstance();

      // Run app
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
        ],
      );
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const FitnessCareApp(),
        ),
      );

      // Register FCM if user is logged in
      // await setupFCM(container);
    },
    (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    },
  );
}
