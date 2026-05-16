import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:fitness_care_bagerhat/app/app.dart';
import 'package:fitness_care_bagerhat/core/auth/token_storage.dart';
import 'package:fitness_care_bagerhat/core/settings/settings_repository.dart';
import 'package:fitness_care_bagerhat/features/member/notifications/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ## bootstrap
///
/// Initializes all services and runs the app.
/// Handles global error boundaries and FCM registration.
Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      await dotenv.load(fileName: '.env');

      // Initialize storage
      final prefs = await SharedPreferences.getInstance();

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

      // Register FCM token if the user is already logged in as a member
      unawaited(_tryRegisterFcm(container));
    },
    (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    },
  );
}

/// Registers the FCM token with the backend if a member token exists.
/// Runs silently — any failure is logged and ignored so it never blocks startup.
Future<void> _tryRegisterFcm(ProviderContainer container) async {
  try {
    final storage = container.read(tokenStorageProvider);
    final role = await storage.getUserRole();
    if (role != 'member') return; // Only members use FCM

    // Firebase is disabled until google-services.json is configured.
    // When Firebase is enabled, uncomment the block below:
    //
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission();
    // final token = await messaging.getToken();
    // if (token == null) return;
    //
    // final notifRepo = container.read(notificationRepositoryProvider);
    // await notifRepo.registerFcmToken(
    //   token: token,
    //   deviceInfo: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    // );
    // log('FCM token registered');
    //
    // messaging.onTokenRefresh.listen((newToken) {
    //   notifRepo.registerFcmToken(token: newToken);
    // });

    log('FCM: Firebase not yet configured — skipping token registration');
  } catch (e, stack) {
    log('FCM registration failed (non-fatal): $e', stackTrace: stack);
  }
}
